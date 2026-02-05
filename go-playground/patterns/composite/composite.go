package composite

type Scorer interface {
	Score() int
}

type User struct {
	score int
}

func NewUser(v int) *User {
	return &User{v}
}

func (u *User) Score() int {
	return u.score
}

type Captain struct {
	*User
	m int
}

func NewCaptain(u *User, m int) *Captain {
	return &Captain{u, m}
}

func (c *Captain) Score() int {
	return c.User.Score() * c.m
}

type Group struct {
	scorers []Scorer
}

func NewGroup(s []Scorer) *Group {
	return &Group{s}
}

func (g *Group) Score() int {
	var score int
	for _, u := range g.scorers {
		score += u.Score()
	}

	return score
}
