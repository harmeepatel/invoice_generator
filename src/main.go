package main

import (
	"bytes"
	"embed"
	"io"
	"io/fs"
	"mime"
	"net/http"
	"path"
	"strings"
	"sync"

	"github.com/a-h/templ"
	"github.com/andybalholm/brotli"
)

const PORT = ":42069"

//go:embed web/static/*
var assets embed.FS

// Templ rendering
// templ.Handler wraps your handler in a bytes.Buffer for rendering.
// A new buffer is allocated for every request — no pooling, so over time the Go runtime may grow heap size to handle worst-case request bursts.
// Fix → Use a sync.Pool to reuse buffers between renders.
var bufPool = sync.Pool{
	New: func() any { return new(bytes.Buffer) },
}

func pooledTemplHandler(c templ.Component) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		buf := bufPool.Get().(*bytes.Buffer)
		buf.Reset()

		// Render into pooled buffer
		if err := c.Render(r.Context(), buf); err != nil {
			http.Error(w, "render error", http.StatusInternalServerError)
			return
		}

		// Write to response
		w.Header().Set("Content-Type", "text/html")
		w.Write(buf.Bytes())

		bufPool.Put(buf)
	})
}

// brotli middleware for static files
func brotliFileServer(fsys fs.FS) http.Handler {
	fileServer := http.FileServer(http.FS(fsys))

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		name := path.Clean(r.URL.Path)
		if strings.Contains(name, "..") {
			http.NotFound(w, r)
			return
		}

		if strings.Contains(r.Header.Get("Accept-Encoding"), "br") {
			brName := name + ".br"

			f, err := fsys.Open(brName)
			if err == nil {
				defer f.Close()

				// Content headers
				w.Header().Set("Content-Encoding", "br")
				w.Header().Add("Vary", "Accept-Encoding")

				if ctype := mime.TypeByExtension(path.Ext(name)); ctype != "" {
					w.Header().Set("Content-Type", ctype)
				}

				// Write file directly
				w.WriteHeader(http.StatusOK)
				_, _ = io.Copy(w, f)
				return
			}
		}

		// Fallback
		fileServer.ServeHTTP(w, r)
	})
}

// brotli middleware for templ html
type brotliResponseWriter struct {
	http.ResponseWriter
	writer *brotli.Writer
}

func brotliMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.Contains(r.Header.Get("Accept-Encoding"), "br") {
			next.ServeHTTP(w, r)
			return
		}

		w.Header().Set("Content-Encoding", "br")
		w.Header().Add("Vary", "Accept-Encoding")

		bw := brotli.NewWriter(w)
		defer bw.Close()

		bwWriter := &brotliResponseWriter{
			ResponseWriter: w,
			writer:         bw,
		}

		next.ServeHTTP(bwWriter, r)
	})
}

func (w *brotliResponseWriter) Write(b []byte) (int, error) {
	return w.writer.Write(b)
}

func main() {
	sid := NewApp()
	sid.RunApp()
}
