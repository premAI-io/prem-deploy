package main

import (
	"bytes"
	"flag"
	"fmt"
	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"
	"net/http"
	"os/exec"
)

var (
	username string
	password string
)

func init() {
	flag.StringVar(&username, "user", "", "Username for authentication")
	flag.StringVar(&password, "pass", "", "Password for authentication")
}

func authenticateMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user, pass, ok := r.BasicAuth()
		if !ok || user != username || pass != password {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func deployHandler(w http.ResponseWriter, r *http.Request) {
	repo := r.URL.Query().Get("repo")
	user := r.URL.Query().Get("user")
	branch := r.URL.Query().Get("branch")

	if repo == "" && user == "" && branch == "" {
		log.Info("No query parameters provided.")
		// No query parameters: Run pull_and_build_all.sh, stop.sh and start.sh
		if _, stderr, err := runCommand("/bin/bash", "pull_and_build_all.sh"); err != nil {
			log.Errorf("Error during pull_and_build_all: %v, stderr: %v", err, stderr)
			http.Error(w, "Pull and build failed.", http.StatusInternalServerError)
			return
		}

		if _, stderr, err := runCommand("/bin/bash", "stop.sh"); err != nil {
			log.Errorf("Error during stop.sh: %v, stderr: %v", err, stderr)
			http.Error(w, "Stop failed.", http.StatusInternalServerError)
			return
		}

		stdout, stderr, err := runCommand("/bin/bash", "start.sh")
		if err != nil {
			log.Errorf("Error during start.sh: %v, stderr: %v", err, stderr)
			http.Error(w, "Start failed.", http.StatusInternalServerError)
			return
		}
		log.Info(stdout)

		if _, err := fmt.Fprintf(w, "Pulled and built all repos, stopped and started containers.\n"); err != nil {
			log.Errorf("Error writing response: %v", err)
		}
	} else if repo != "" && user != "" && branch != "" {
		log.Infof("Query parameters provided: repo=%s, user=%s, branch=%s", repo, user, branch)
		// Query parameters provided: Run pull_and_build.sh with parameters and restart containers
		if _, stderr, err := runCommand("/bin/bash", "pull_and_build.sh", user, repo, branch); err != nil {
			log.Errorf("Error during pull_and_build.sh: %v, stderr: %v", err, stderr)
			http.Error(w, "Pull and build failed.", http.StatusInternalServerError)
			return
		}

		if _, stderr, err := runCommand("/bin/bash", "stop.sh"); err != nil {
			log.Errorf("Error during stop.sh:  %v, stderr: %v", err, stderr)
			http.Error(w, "Stop failed.", http.StatusInternalServerError)
			return
		}

		if _, stderr, err := runCommand("/bin/bash", "start.sh"); err != nil {
			log.Errorf("Error during start.sh: %v, stderr: %v", err, stderr)
			http.Error(w, "Stop start.", http.StatusInternalServerError)
			return
		}

		if _, err := fmt.Fprintf(w, "Pulled and built %s and restarted containers.\n", repo); err != nil {
			log.Error(err)
		}
	} else {
		// Invalid query parameters
		if _, err := fmt.Fprintf(w, "Invalid parameters. Use either none or all of [repo, user, branch].\n"); err != nil {
			log.Error(err)
		}
	}
}

func runCommand(command string, args ...string) (string, string, error) {
	cmd := exec.Command(command, args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()

	return stdout.String(), stderr.String(), err
}

func main() {
	flag.Parse()
	if username == "" || password == "" {
		log.Fatal("Both username (-user) and password (-pass) must be provided.")
	}

	r := mux.NewRouter()
	deployRouter := r.Path("/deploy").Subrouter()
	deployRouter.Use(authenticateMiddleware)
	deployRouter.HandleFunc("", deployHandler).Methods(http.MethodPost)

	log.Println("Server listening on port 9000...")
	log.Fatal(http.ListenAndServe(":9000", r))
}
