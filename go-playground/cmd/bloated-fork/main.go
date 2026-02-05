package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"syscall"
	"time"
)

func main() {
	// check command line flags, configuration etc.

	// short delay to avoid race condition between os.StartProcess and os.Exit
	// can be omitted if the work done above amounts to a sufficient delay
	time.Sleep(2 * time.Second)

	if os.Getppid() != 1 {
		// I am the parent, spawn child to run as daemon
		binary, err := exec.LookPath(os.Args[0])
		if err != nil {
			log.Fatalln("Failed to lookup binary:", err)
		}
		_, err = os.StartProcess(binary, os.Args, &os.ProcAttr{Dir: "", Env: nil,
			Files: []*os.File{os.Stdin, os.Stdout, os.Stderr}, Sys: nil})
		if err != nil {
			log.Fatalln("Failed to start process:", err)
		}
		log.Printf("parent: pid: %d: ppid: %d", os.Getpid(), os.Getppid())
		os.Exit(0)
	} else {
		// I am the child, i.e. the daemon, start new session and detach from terminal
		_, err := syscall.Setsid()
		if err != nil {
			log.Fatalln("Failed to create new session:", err)
		}
		file, err := os.OpenFile("log.log", os.O_RDWR, 0)
		if err != nil {
			log.Fatalln("Failed to open log.log:", err)
		}
		syscall.Dup2(int(file.Fd()), int(os.Stdin.Fd()))
		syscall.Dup2(int(file.Fd()), int(os.Stdout.Fd()))
		syscall.Dup2(int(file.Fd()), int(os.Stderr.Fd()))

		log.Printf("child: pid: %d: ppid: %d", os.Getpid(), os.Getppid())
		file.Close()
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "http: pid: %d: ppid: %d", os.Getpid(), os.Getppid())
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
