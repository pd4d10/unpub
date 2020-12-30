package unpub

import (
	"time"

	"github.com/gin-gonic/gin"
)

// VersionPayload VersionPayload
type VersionPayload struct {
	PubspecYaml string
	Readme      string
	Changelog   string
	Pubspec     map[string]interface{}
	Name        string
	Version     string
	Uploader    string
}

// MetaStore MetaStore
type MetaStore interface {
	QueryPackage(name string) *PubPackage
	AddVersion(p VersionPayload) error
}

// TarballStore TarballStore
type TarballStore interface {
	Upload(name string, version string, data []byte) error
	Download(name string, version string) ([]byte, error)
}

var metaStore MetaStore
var tarballStore TarballStore

// SetupRouter SetupRouter
func SetupRouter(meta MetaStore, tarball TarballStore) *gin.Engine {
	metaStore = meta
	tarballStore = tarball

	router := gin.Default()
	router.POST("/api/packages/versions/newUpload", PackagesNewUpload)
	router.GET("/api/packages/*action", PackagesFallback)
	return router
}

const (
	timeout    = 3 * time.Second
	upstream   = "https://pub.dev"
	scheme     = "http://"
	mongodbURI = "mongodb://127.0.0.1:27017"
)
