package main

import (
	"bufio"
	"fmt"
	"github.com/labstack/gommon/log"
	"io"
	"os"
	"os/exec"
	"syscall"
)

func main() {
	c:="/usr/local/Cellar/leela-zero/0.17/bin/leelaz -g --cpu-only -t 1  --noponder --playouts 100  -w /Users/laozhang/.local/share/leela-zero/weights.txt"
	conn ,err:= NewConnection("sh","-c",c)
	if err != nil {
		log.Print(err)
	}
	input := bufio.NewScanner(os.Stdin)
	for input.Scan() {
		a := input.Text()
		out:=conn.Exec(a)

		fmt.Println(out)
	}


}

func stopProcess(cmd *exec.Cmd) error {
	pro, err := os.FindProcess(cmd.Process.Pid)
	if err != nil {
		return err
	}
	err = pro.Signal(syscall.SIGINT)
	if err != nil {
		return err
	}
	fmt.Printf("结束子进程%s成功\n", cmd.Path)
	return nil
}

// GTP_Connection GTP连接类管理
type GTPConnection struct {
	cmd     *exec.Cmd
	infile  io.WriteCloser
	outfile io.ReadCloser
}

// NewConnection 创建GTP连接
func NewConnection(cmd string, args ...string) (GTPConnection, error) {
	conn := GTPConnection{}
	conn.cmd = exec.Command(cmd, args...)
	inf, err := conn.cmd.StdinPipe()
	if err != nil {
		return conn, err
	}
	outf, err := conn.cmd.StdoutPipe()
	if err != nil {
		return conn, err
	}
	conn.infile = inf
	conn.outfile = outf
	conn.cmd.Start()
	go func() {
		conn.cmd.Wait()
	}()
	return conn, nil
}

// Exec 执行GTP命令
func (self GTPConnection) Exec(cmd string) (string) {
	self.infile.Write([]byte(fmt.Sprintf("%s\n", cmd)))
	reader := bufio.NewReader(self.outfile)
	result := ""
	for {
		line, err2 := reader.ReadString('\n')
		if err2 != nil || io.EOF == err2 {
			break
		}
		if line == "\n" {
			break
		}
		result += line
	}

	return result
}
