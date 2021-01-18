package router

import (
	"regexp"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestNew(t *testing.T) {
	want := regexp.MustCompile(`^\{(".*":.*)+\}\n+$`)

	// setup router
	gin.SetMode(gin.TestMode)
	New()

	if !want.Match(testModeOutputBuffer.Bytes()) {
		t.Errorf("\n+ %s\n- %s", testModeOutputBuffer.String(), want.String())
	}
}
