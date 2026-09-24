package main

import (
	"net/http/httptest"
	"testing"
)

func TestHandler(t *testing.T) {
	req := httptest.NewRequest("GET", "/", nil)
	rec := httptest.NewRecorder()

	oldVersion := version
	version = "test"
	defer func() {
		version = oldVersion
	}()

	handler(rec, req)

	got := rec.Body.String()
	want := "Hello, DevOps! version=test\n"

	if got != want {
		t.Fatalf("got %q, want %q", got, want)
	}
}
