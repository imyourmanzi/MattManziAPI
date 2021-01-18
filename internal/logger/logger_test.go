package logger

import (
	"bytes"
	"fmt"
	"regexp"
	"testing"

	"github.com/sirupsen/logrus"
)

func TestNew(t *testing.T) {
	// expected output must match
	msg := `It works!`
	logFormat := `^\{"environment":".+","level":"%s","msg":"` + msg + `","service":"mattmanziapi","time":"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}([+-]?\d{2}:?\d{2}|Z)?"\}\n$`
	var want *regexp.Regexp

	// setup logger output capture
	log := New()
	var got bytes.Buffer
	log.Logger.SetOutput(&got)
	log.Logger.SetLevel(logrus.DebugLevel)

	// log a debug
	got.Reset()
	want = regexp.MustCompile(fmt.Sprintf(logFormat, "debug"))
	log.Debug(msg)
	if !want.Match(got.Bytes()) {
		t.Errorf("\n+ %s\n- %s", got.String(), want.String())
	}

	// log an info
	got.Reset()
	want = regexp.MustCompile(fmt.Sprintf(logFormat, "info"))
	log.Info(msg)
	if !want.Match(got.Bytes()) {
		t.Errorf("\n+ %s\n- %s", got.String(), want.String())
	}

	// log a warn
	got.Reset()
	want = regexp.MustCompile(fmt.Sprintf(logFormat, "warning"))
	log.Warn(msg)
	if !want.Match(got.Bytes()) {
		t.Errorf("\n+ %s\n- %s", got.String(), want.String())
	}

	// log an error
	got.Reset()
	want = regexp.MustCompile(fmt.Sprintf(logFormat, "error"))
	log.Error(msg)
	if !want.Match(got.Bytes()) {
		t.Errorf("\n+ %s\n- %s", got.String(), want.String())
	}
}
