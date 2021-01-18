package logger

import (
	"bytes"
	"fmt"
	"regexp"
	"testing"
)

func TestNew(t *testing.T) {
	// expected output must match
	msg := `It works!`
	logFormat := `^\{"environment":".+","level":"%s","msg":"` + msg + `","service":"mattmanziapi","time":"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}([+-]?\d{2}:?\d{2}|Z)?"\}\n+$`
	var want *regexp.Regexp

	// setup logger output capture
	log := New()
	var got bytes.Buffer
	log.Logger.SetOutput(&got)

	// log an info
	want = regexp.MustCompile(fmt.Sprintf(logFormat, "info"))
	log.Info(msg)
	if !want.Match(got.Bytes()) {
		t.Errorf("\n+ %s\n- %s", got.String(), want.String())
	}
	got.Reset()

	// log a warn
	want = regexp.MustCompile(fmt.Sprintf(logFormat, "warning"))
	log.Warn(msg)
	if !want.Match(got.Bytes()) {
		t.Errorf("\n+ %s\n- %s", got.String(), want.String())
	}
	got.Reset()

	// log an error
	want = regexp.MustCompile(fmt.Sprintf(logFormat, "error"))
	log.Error(msg)
	if !want.Match(got.Bytes()) {
		t.Errorf("\n+ %s\n- %s", got.String(), want.String())
	}
}
