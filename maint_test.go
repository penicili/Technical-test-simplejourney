package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHandlerStatusOK(t *testing.T) {
	rec := httptest.NewRecorder()
	handler(rec, httptest.NewRequest(http.MethodGet, "/", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
}

func TestHandlerReportsVersion(t *testing.T) {
	old := version
	version = "9.9.9"
	defer func() { version = old }()

	rec := httptest.NewRecorder()
	handler(rec, httptest.NewRequest(http.MethodGet, "/", nil))
	if !strings.Contains(rec.Body.String(), "version=9.9.9") {
		t.Fatalf("unexpected body: %q", rec.Body.String())
	}
}