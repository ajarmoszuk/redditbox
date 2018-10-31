package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"syscall"
	"unsafe"
	"time"

	"github.com/gliderlabs/ssh"
	"github.com/kr/pty"
)

func setWinsize(f *os.File, w, h int) {
	syscall.Syscall(syscall.SYS_IOCTL, f.Fd(), uintptr(syscall.TIOCSWINSZ),
		uintptr(unsafe.Pointer(&struct{ h, w, x, y uint16 }{uint16(h), uint16(w), 0, 0})))
}

func main() {
	ssh.Handle(func(s ssh.Session) {
		log.Printf("Connection from %s (%s)", s.RemoteAddr(), s.User())
		b, err := ioutil.ReadFile("/app/motd")
    		if err != nil {
        		log.Print(err)
    		}

    		io.WriteString(s, string(b))
		io.WriteString(s, fmt.Sprintf("Hello %s!\n", s.User()))
		time.Sleep(1 * time.Second)

		cmd := exec.Command("/app/wrapper")
		ptyReq, winCh, isPty := s.Pty()
		if isPty {
			cmd.Env = append(cmd.Env, fmt.Sprintf("TERM=%s", ptyReq.Term))
			f, err := pty.Start(cmd)
			if err != nil {
				panic(err)
			}
			go func() {
				for win := range winCh {
					setWinsize(f, win.Width, win.Height)
				}
			}()
			go func() {
				io.Copy(f, s) // stdin
			}()
			io.Copy(s, f) // stdout
		} else {
			io.WriteString(s, "No PTY requested.\n")
			s.Exit(1)
		}
	})

	log.Println("SSH server started...")
	log.Fatal(ssh.ListenAndServe(":22", nil, ssh.HostKeyFile("/app/id_rsa")))
}
