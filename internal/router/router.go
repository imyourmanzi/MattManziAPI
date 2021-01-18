// Package router defines and delivers a custom Gin router engine.
package router

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/imyourmanzi/MattManziAPI/internal/logger"
	"github.com/sirupsen/logrus"
)

// The shared router instance.
var r *gin.Engine

// ginLogger defines the middleware for custom Gin router engine logging.
func ginLogger() gin.HandlerFunc {
	var ginLog = logger.New()

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

// New creates a new Gin Engine with custom logging and the Gin Recovery
// middleware attached.
func New() *gin.Engine {
	if r != nil {
		return r
	}

	r = gin.New()

	// install middleware
	r.Use(ginLogger())
	r.Use(gin.Recovery())

	return r
}
