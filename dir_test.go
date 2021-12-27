package main

import (
	"os"
	"path"
	"syscall"
	"testing"
)

func TestDirError(t *testing.T) {
	dir := t.TempDir()
	pathToFile := path.Join(dir, "foo")
	if os.WriteFile(pathToFile, []byte{}, 0600) != nil {
		t.Fatalf("cannot write %s", pathToFile)
	}
	noteThisIsAFileNotADir, err := os.Open(pathToFile)
	defer noteThisIsAFileNotADir.Close()

	if err != nil {
		t.Fatalf("cannot open %s", pathToFile)
	}
	_, err = noteThisIsAFileNotADir.ReadDir(1)
	if err == nil {
		t.Fatalf("wanted an error on os.File(%s).ReadDir()", pathToFile)
	}
	pErr, ok := err.(*os.PathError)
	if !ok {
		t.Fatalf("wanted an os.PathError on os.ReadDir(%s)", pathToFile)
	}
	if pErr.Err != syscall.ENOTDIR {
		t.Fatalf("want syscall.ENOTDIR, have %s, on os.ReadDir(%s)", pErr.Err, pathToFile)
	}
}
