package main

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"

	"github.com/imyourmanzi/MattManziAPI/internal/logger"
)

var log = logger.NewLogger("main")

func ginLogger() gin.HandlerFunc {
	var ginLog = logger.NewLogger("gin")

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

func main() {
	log.Println("Starting API...")
	r := gin.New()

	r.Use(ginLogger())

	r.Use(gin.Recovery())

	r.GET("/version", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"version": "0.1.0"})
	})

	r.Run("localhost:8080")
}
