package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

type LogEntry struct {
	Time    string `json:"time"`
	Level   string `json:"level"`
	Message string `json:"message"`
	Path    string `json:"path,omitempty"`
	Method  string `json:"method,omitempty"`
}

func logJSON(level, message string, r *http.Request) {
	entry := LogEntry{
		Time:    time.Now().Format(time.RFC3339),
		Level:   level,
		Message: message,
	}

	if r != nil {
		entry.Path = r.URL.Path
		entry.Method = r.Method
	}

	logBytes, _ := json.Marshal(entry)
	log.Println(string(logBytes))
}

var (
	httpRequests = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "path"},
	)

	httpDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Request latency",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "path"},
	)
)

func init() {
	prometheus.MustRegister(httpRequests)
	prometheus.MustRegister(httpDuration)
}

func main() {
	port := getEnv("PORT", "8080")

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		httpRequests.WithLabelValues(r.Method, r.URL.Path).Inc()

		logJSON("INFO", "Request received", r)

		w.Write([]byte("Hello from secure Go app\n"))

		duration := time.Since(start).Seconds()
		httpDuration.WithLabelValues(r.Method, r.URL.Path).Observe(duration)
	})

	// 🔥 Prometheus endpoint
	http.Handle("/metrics", promhttp.Handler())

	logJSON("INFO", "Starting server on port "+port, nil)

	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		logJSON("ERROR", err.Error(), nil)
	}
}

func getEnv(key, fallback string) string {
	val := os.Getenv(key)
	if val == "" {
		return fallback
	}
	return val
}
