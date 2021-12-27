package main

import (
	"os"
	"path"
	"syscall"
	"testing"
)

func TestDirError(t *testing.T) {
	dir := t.TempDir()
	fileNotDir := path.Join(dir, "foo")
	if os.WriteFile(fileNotDir, []byte{}, 0600) != nil {
		t.Fatalf("cannot write %s", fileNotDir)
	}
	_, err := os.ReadDir(fileNotDir)
	if err == nil {
		t.Fatalf("wanted an error on os.ReadDir(%s)", fileNotDir)
	}
	pErr, ok := err.(*os.PathError)
	if !ok {
		t.Fatalf("wanted an os.PathError on os.ReadDir(%s)", fileNotDir)
	}
	if os.IsNotExist(err) {
		t.Fatalf("didn't want os.IsNotExist() on os.ReadDir(%s)", fileNotDir)
	}
	if pErr.Err != syscall.ENOTDIR {
		t.Fatalf("want syscall.ENOTDIR, have %s, on os.ReadDir(%s)", pErr.Err, fileNotDir)
	}
}
