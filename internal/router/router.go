// Package router defines and delivers a custom Gin router engine.
package router

import (
	"bytes"
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/imyourmanzi/MattManziAPI/internal/logger"
	"github.com/sirupsen/logrus"
)

var log = logger.New()

// The shared router instance.
var r *gin.Engine

// A buffer that can be used to read log output when Gin is running in TestMode.
var testModeOutputBuffer bytes.Buffer

// ginLogger defines the middleware for custom Gin router engine logging.
func ginLogger() gin.HandlerFunc {
	var ginLog = logger.New()

	if gin.Mode() == gin.TestMode {
		ginLog.Logger.SetOutput(&testModeOutputBuffer)
		ginLog.Logger.SetLevel(logrus.InfoLevel)
		ginLog.WithField("mode", gin.Mode()).Info("Gin is running")
	}

	return func(c *gin.Context) {
		// start timer
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		if raw != "" {
			path = path + "?" + raw
		}

		// process request
		c.Next()

		// stop timer
		stop := time.Now()
		latency := stop.Sub(start)

		errorMessage := c.Errors.ByType(gin.ErrorTypePrivate).String()

		finalLog := ginLog.WithFields(logrus.Fields{
			"datetime":      stop,
			"latency":       latency,
			"latencyPretty": fmt.Sprintf("%v", latency),
			"remoteIP":      c.ClientIP(),
			"method":        c.Request.Method,
			"status":        c.Writer.Status(),
			"size":          c.Writer.Size(),
			"path":          path,
		})

		if errorMessage != "" {
			finalLog.Error(errorMessage)
		} else {
			finalLog.Info()
		}
	}
}

// New creates a new Gin engine with custom logging and the Gin Recovery
// middleware attached.
func New() *gin.Engine {
	if r != nil {
		log.Warn("New router requested, but one already exists, returing it")
		return r
	}

	r = gin.New()

	// install middleware
	r.Use(ginLogger())
	r.Use(gin.Recovery())

	log.Info("Initialized new router")
	return r
}
