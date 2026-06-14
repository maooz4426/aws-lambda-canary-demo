package hello

import (
	"errors"
	"fmt"
)

type HelloService struct {
	Version string
}

func NewHelloService(version string) *HelloService {
	return &HelloService{Version: version}
}

func (s *HelloService) SayHello() (string, error) {
	if s.Version == "" {
		return "", errors.New("empty version")
	}
	return fmt.Sprintf("Hello %s", s.Version), nil
}
