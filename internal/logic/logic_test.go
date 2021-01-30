package logic_test

import (
	"testing"

	"github.com/franela/goblin"
	"github.com/imyourmanzi/MattManziAPI/internal/logic"
)

func TestLogicPackage(t *testing.T) {
	g := goblin.Goblin(t)

	g.Describe("AllAreSame function", func() {
		g.It("works with 1 `true` operand", func() {
			got := logic.AreAllSame(true)
			g.Assert(got).Equal(true)
		})

		g.It("works with 1 `false` operand", func() {
			got := logic.AreAllSame(false)
			g.Assert(got).Equal(true)
		})

		g.It("works with 2 like operands", func() {
			got1 := logic.AreAllSame(true, true)
			g.Assert(got1).Equal(true)
			got2 := logic.AreAllSame(false, false)
			g.Assert(got2).Equal(true)
		})

		g.It("works with 2 unlike operands", func() {
			got1 := logic.AreAllSame(false, true)
			g.Assert(got1).Equal(false)
			got2 := logic.AreAllSame(true, false)
			g.Assert(got2).Equal(false)
		})

		g.It("works with several operands", func() {
			got1 := logic.AreAllSame(false, false, false, false, false)
			g.Assert(got1).Equal(true)
			got2 := logic.AreAllSame(false, false, false, false, true)
			g.Assert(got2).Equal(false)
		})
	})
}
