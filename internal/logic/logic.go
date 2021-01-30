// Package logic provides extension for bitwise functionality in Go,
// especially for boolean types.
package logic

// AreAllSame returns whether or not all operands are either true or false.
func AreAllSame(first bool, operands ...bool) bool {
	prev := first
	for _, op := range operands {

		// the next operand must match the last one if all are to be the same
		if op != prev {
			return false
		}
		prev = op
	}

	return true
}
