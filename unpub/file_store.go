package unpub

import (
	"io/ioutil"
	"os"
	"path"
)

// FileStore FileStore
type FileStore struct {
	BaseDir string
}

func (f FileStore) getFilePath(name string, version string) string {
	return path.Join(f.BaseDir, name, "-", version, ".tar.gz")
}

// Init Init
func (f FileStore) Init(baseDir string) {
	f.BaseDir = baseDir
	_ = os.Mkdir(f.BaseDir, os.ModeDir)
}

// Upload Upload
func (f FileStore) Upload(name string, version string, data []byte) error {
	p := f.getFilePath(name, version)
	return ioutil.WriteFile(p, data, 0644)
}

// Download Download
func (f FileStore) Download(name string, version string) ([]byte, error) {
	p := f.getFilePath(name, version)
	return ioutil.ReadFile(p)
}
