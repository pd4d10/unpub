package unpub

import (
	"log"
	"net/http"
	"net/http/httptest"
	"os"
	"path"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPackageFallback(t *testing.T) {
	metaStore := MongoStore{}
	metaStore.Init(mongodbURI)

	cwd, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}
	tarballStore := FileStore{}
	tarballStore.Init(path.Join(cwd, "unpub-packages"))

	router := SetupRouter(metaStore, tarballStore)

	t.Run("newUploadFinish", func(t *testing.T) {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/packages/versions/new", nil)
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
	})

	t.Run("newUploadFinish", func(t *testing.T) {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/packages/versions/newUploadFinish", nil)
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
	})

	t.Run("newUploadFinish", func(t *testing.T) {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/packages/versions/newUploadFinish?error=abc", nil)
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}
