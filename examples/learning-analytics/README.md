# Learning analytics: from event to construct

An executable R-ClaimLab lesson about event logs, construct validity, repeated observations, privacy, and descriptive learner evidence. The dataset contains 18 synthetic learner-session summaries for six synthetic learners across three sessions. It contains no real learner records and must not be treated as a model of individual ability.

The lesson makes the grain explicit: one row is one learner-session summary, `learner_id` is a grouping variable, and `session` is ordered time. The core package therefore recommends descriptive exploration and warns that its simple `lm` and `glm` adapters do not model repeated observations.

Run `quarto render`, open `scene/index.html`, and run `rclaimlab::check_lesson(".", strict = TRUE)` before adapting the lesson.
