note
	description: "Console test runner for simple_speed_reader."
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			print ("Running SIMPLE_SPEED_READER tests...%N%N")
			passed := 0
			failed := 0

			run_engine_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_engine_tests
		local
			l_set: SPEED_READER_TEST_SET
		do
			create l_set
			print ("=== ORP LAW ===%N")
			run_test (agent l_set.test_pivot_law, "test_pivot_law")
			run_test (agent l_set.test_pivot_avoids_combining_marks, "test_pivot_avoids_combining_marks")
			print ("=== CLASSIFICATION ===%N")
			run_test (agent l_set.test_classification_hebrew, "test_classification_hebrew")
			run_test (agent l_set.test_classification_greek, "test_classification_greek")
			run_test (agent l_set.test_classification_transliteration, "test_classification_transliteration")
			run_test (agent l_set.test_classification_numeric_and_acronym, "test_classification_numeric_and_acronym")
			print ("=== TOKENIZER ===%N")
			run_test (agent l_set.test_tokenizer_structure, "test_tokenizer_structure")
			run_test (agent l_set.test_tokenizer_quoted_sentence_end, "test_tokenizer_quoted_sentence_end")
			run_test (agent l_set.test_tokenizer_blank_query, "test_tokenizer_blank_query")
			print ("=== GOVERNOR ===%N")
			run_test (agent l_set.test_governor_ramp, "test_governor_ramp")
			run_test (agent l_set.test_governor_hold_and_release, "test_governor_hold_and_release")
			run_test (agent l_set.test_governor_back_off_keeps_comfy, "test_governor_back_off_keeps_comfy")
			run_test (agent l_set.test_governor_back_off_after_hold_stays_low, "test_governor_back_off_after_hold_stays_low")
			run_test (agent l_set.test_governor_recovery, "test_governor_recovery")
			print ("=== TIMING ===%N")
			run_test (agent l_set.test_timing_base_and_length, "test_timing_base_and_length")
			run_test (agent l_set.test_timing_foreign_floor, "test_timing_foreign_floor")
			run_test (agent l_set.test_timing_breathers, "test_timing_breathers")
			print ("=== PACER ===%N")
			run_test (agent l_set.test_pacer_anchoring_no_drift, "test_pacer_anchoring_no_drift")
			run_test (agent l_set.test_pacer_far_behind, "test_pacer_far_behind")
			print ("=== SESSION ===%N")
			run_test (agent l_set.test_session_full_read, "test_session_full_read")
			run_test (agent l_set.test_session_pause_resume_recovery, "test_session_pause_resume_recovery")
			run_test (agent l_set.test_session_zero_click_resume, "test_session_zero_click_resume")
			run_test (agent l_set.test_session_foreign_skip, "test_session_foreign_skip")
			run_test (agent l_set.test_session_replay_and_skip, "test_session_replay_and_skip")
			run_test (agent l_set.test_session_stop_keeps_position, "test_session_stop_keeps_position")
			run_test (agent l_set.test_facade_blank_intake, "test_facade_blank_intake")
		end

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

	passed, failed: INTEGER

end
