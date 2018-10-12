cnf(c_0_0, axiom, (subset(X1,X2)|~equal_sets(X1,X2)), file('../CNF_PROBLEMS_THM/Axioms/SET001-0.ax', set_equal_sets_are_subsets1)).
cnf(c_0_1, hypothesis, (equal_sets(b,bb)), file('../CNF_PROBLEMS_THM/SET001-1.p', b_equals_bb)).
cnf(c_0_2, axiom, (member(X1,X3)|~member(X1,X2)|~subset(X2,X3)), file('../CNF_PROBLEMS_THM/Axioms/SET001-0.ax', membership_in_subsets)).
cnf(c_0_3, negated_conjecture, (~member(element_of_b,bb)), file('../CNF_PROBLEMS_THM/SET001-1.p', prove_element_of_bb)).
cnf(c_0_4, hypothesis, (member(element_of_b,b)), file('../CNF_PROBLEMS_THM/SET001-1.p', element_of_b)).
cnf(c_0_5, hypothesis, (subset(b,bb)), inference(spm,[status(thm)],[c_0_0, c_0_1])).
cnf(c_0_6, hypothesis, (member(X1,bb)|~member(X1,b)), inference(spm,[status(thm)],[c_0_2, c_0_5])).
cnf(c_0_7, negated_conjecture, ($false), inference(cn,[status(thm)],[inference(rw,[status(thm)],[inference(spm,[status(thm)],[c_0_3, c_0_6]), c_0_4])]), ['proof']).

