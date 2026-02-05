package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"syscall"
)

func main() {
	// var id int
	if os.Getppid() != 1 {
		binPath, err := exec.LookPath(os.Args[0])
		if err != nil {
			os.Exit(1)
		}

		cmd := exec.Command(binPath, os.Args[1:]...)
		cmd.SysProcAttr = &syscall.SysProcAttr{
			// Setsid: true,
		}
		err = cmd.Start()
		if err != nil {
			log.Printf("%s\n", err)
		}
		log.Printf("parent: pid: %d: ppid: %d: args: %v, NumCPU: %d, GOMAXPROCS: %d",
			os.Getpid(), os.Getppid(), os.Args, runtime.NumCPU(), runtime.GOMAXPROCS(0))
		os.Exit(0)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "http: pid: %d: ppid: %d: args: %v, NumCPU: %d, GOMAXPROCS: %d",
			os.Getpid(), os.Getppid(), os.Args, runtime.NumCPU(), runtime.GOMAXPROCS(0))
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
