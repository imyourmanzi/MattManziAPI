package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()

	router.GET("/version", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"version": "0.1.0"})
	})

	router.Run()
}
