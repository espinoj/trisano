require File.dirname(__FILE__) + "/helper"

with_steps_for(:people) do
  run_local_story "people_story"
end