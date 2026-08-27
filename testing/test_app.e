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
			print ("=== READING WINDOW ===%N")
			run_test (agent l_set.test_window_span_law, "test_window_span_law")
			print ("=== CLASSIFICATION ===%N")
			run_test (agent l_set.test_classification_hebrew, "test_classification_hebrew")
			run_test (agent l_set.test_classification_greek, "test_classification_greek")
			run_test (agent l_set.test_classification_transliteration, "test_classification_transliteration")
			run_test (agent l_set.test_classification_numeric_and_acronym, "test_classification_numeric_and_acronym")
			print ("=== TOKENIZER ===%N")
			run_test (agent l_set.test_tokenizer_structure, "test_tokenizer_structure")
			run_test (agent l_set.test_tokenizer_quoted_sentence_end, "test_tokenizer_quoted_sentence_end")
			run_test (agent l_set.test_tokenizer_blank_query, "test_tokenizer_blank_query")
			run_test (agent l_set.test_tokenizer_sections_from_headings, "test_tokenizer_sections_from_headings")
			run_test (agent l_set.test_session_structure_navigation, "test_session_structure_navigation")
			print ("=== GOVERNOR ===%N")
			run_test (agent l_set.test_governor_ramp, "test_governor_ramp")
			run_test (agent l_set.test_governor_hold_and_release, "test_governor_hold_and_release")
			run_test (agent l_set.test_governor_back_off_keeps_comfy, "test_governor_back_off_keeps_comfy")
			run_test (agent l_set.test_governor_back_off_after_hold_stays_low, "test_governor_back_off_after_hold_stays_low")
			run_test (agent l_set.test_governor_step_tiers, "test_governor_step_tiers")
			run_test (agent l_set.test_governor_recovery, "test_governor_recovery")
			print ("=== TIMING ===%N")
			run_test (agent l_set.test_timing_base_and_length, "test_timing_base_and_length")
			run_test (agent l_set.test_timing_foreign_floor, "test_timing_foreign_floor")
			run_test (agent l_set.test_timing_breathers, "test_timing_breathers")
			run_test (agent l_set.test_timing_fade_alpha, "test_timing_fade_alpha")
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
			print ("%N=== HARDENING (adversarial) ===%N")
			run_test (agent l_set.test_adversarial_single_word, "test_adversarial_single_word")
			run_test (agent l_set.test_adversarial_all_foreign_with_skip, "test_adversarial_all_foreign_with_skip")
			run_test (agent l_set.test_adversarial_monster_word, "test_adversarial_monster_word")
			run_test (agent l_set.test_adversarial_punctuation_noise, "test_adversarial_punctuation_noise")
			run_test (agent l_set.test_adversarial_rapid_pause_resume, "test_adversarial_rapid_pause_resume")
			run_test (agent l_set.test_adversarial_governor_floor_everything, "test_adversarial_governor_floor_everything")
			run_test (agent l_set.test_adversarial_boundary_jumps, "test_adversarial_boundary_jumps")
			run_test (agent l_set.test_adversarial_quiz_garbage_payloads, "test_adversarial_quiz_garbage_payloads")
			run_test (agent l_set.test_adversarial_large_text_stress, "test_adversarial_large_text_stress")
			print ("=== STORE ===%N")
			run_test (agent l_set.test_settings_roundtrip, "test_settings_roundtrip")
			run_test (agent l_set.test_log_records_and_reads, "test_log_records_and_reads")
			run_test (agent l_set.test_preset_position_continue, "test_preset_position_continue")
			print ("=== WORD CLOUD ===%N")
			run_test (agent l_set.test_wordcloud_ranks_and_scopes, "test_wordcloud_ranks_and_scopes")
			run_test (agent l_set.test_wordcloud_survives_greek, "test_wordcloud_survives_greek")
			print ("=== QUIZ ===%N")
			run_test (agent l_set.test_validator_normalizes_whitespace, "test_validator_normalizes_whitespace")
			run_test (agent l_set.test_quiz_parse_validate_score, "test_quiz_parse_validate_score")
			run_test (agent l_set.test_quiz_error_payload_degrades, "test_quiz_error_payload_degrades")
			print ("=== BRAKING ===%N")
			run_test (agent l_set.test_governor_brake_cycle, "test_governor_brake_cycle")
			run_test (agent l_set.test_governor_brake_restores_hold, "test_governor_brake_restores_hold")
			run_test (agent l_set.test_session_scrub_back, "test_session_scrub_back")
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
