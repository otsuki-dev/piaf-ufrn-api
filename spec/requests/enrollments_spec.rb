# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enrollments API", type: :request do
  let(:student) { create(:user) }
  let(:instructor) { create(:user, :instructor) }
  let(:admin) { create(:user, :admin) }
  let(:course) { create(:course, user: instructor, slots: 10) }

  describe "POST /api/v1/enrollments" do
    it "enrolls an authenticated student as confirmed" do
      api_post "/api/v1/enrollments", {
        course_id: course.id,
        terms_accepted: true,
        other_reasons: true
      }, sign_in_via_api(student)

      expect(response).to have_http_status(:created)
      expect(json_payload.dig("data", "status")).to eq("confirmed")
      expect(json_payload.dig("data", "user", "id")).to eq(student.id)
      expect(json_payload.dig("data", "other_reasons")).to eq(true)
    end

    it "sends the student to the waitlist when the class is full" do
      create(:enrollment, course: course) # reaches the single slot
      course.update!(slots: 1)

      api_post "/api/v1/enrollments", { course_id: course.id, terms_accepted: true },
               sign_in_via_api(student)

      expect(response).to have_http_status(:created)
      expect(json_payload.dig("data", "status")).to eq("waitlisted")
    end

    it "requires authentication" do
      api_post "/api/v1/enrollments", { course_id: course.id, terms_accepted: true }
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects duplicate active enrollments" do
      create(:enrollment, user: student, course: course)

      api_post "/api/v1/enrollments", { course_id: course.id, terms_accepted: true },
               sign_in_via_api(student)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects requests without terms acceptance" do
      api_post "/api/v1/enrollments", { course_id: course.id }, sign_in_via_api(student)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_payload.dig("errors", 0, "source", "pointer")).to eq("/data/attributes/terms_accepted")
    end
  end

  describe "GET /api/v1/enrollments" do
    let!(:own) { create(:enrollment, user: student, course: course) }
    let!(:other) { create(:enrollment, course: course) }

    it "lists only the student's own enrollments" do
      api_get "/api/v1/enrollments", {}, sign_in_via_api(student)

      expect(response).to have_http_status(:ok)
      expect(json_payload["data"].map { |e| e["id"] }).to eq([ own.id ])
    end

    it "lists enrollments of the instructor's courses" do
      api_get "/api/v1/enrollments", {}, sign_in_via_api(instructor)

      expect(response).to have_http_status(:ok)
      expect(json_payload["data"].map { |e| e["id"] }).to include(own.id, other.id)
    end

    it "lets admins list every enrollment filtered by status" do
      api_get "/api/v1/enrollments", { status: "waitlisted" }, sign_in_via_api(admin)

      expect(response).to have_http_status(:ok)
      expect(json_payload["data"].map { |e| e["id"] }).to be_empty
    end
  end

  describe "GET /api/v1/enrollments/:id" do
    let(:enrollment) { create(:enrollment, user: student, course: course) }

    it "shows the owner the detailed view with anamnesis" do
      api_get "/api/v1/enrollments/#{enrollment.id}", {}, sign_in_via_api(student)

      expect(response).to have_http_status(:ok)
      expect(json_payload.dig("data", "status")).to eq("confirmed")
      expect(json_payload.dig("data", "attendance_rate")).to be_nil
    end

    it "shows the course instructor the detail view" do
      api_get "/api/v1/enrollments/#{enrollment.id}", {}, sign_in_via_api(instructor)

      expect(response).to have_http_status(:ok)
    end

    it "hides another student's enrollment" do
      other_student = create(:user)
      api_get "/api/v1/enrollments/#{enrollment.id}", {}, sign_in_via_api(other_student)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/enrollments/:id" do
    it "cancels the enrollment and promotes the waitlist" do
      course = create(:course, user: instructor, slots: 1)
      confirmed = create(:enrollment, user: student, course: course)
      waitlisted_user = create(:user)
      waitlisted = create(:enrollment, :waitlisted, user: waitlisted_user, course: course)

      api_delete "/api/v1/enrollments/#{confirmed.id}", sign_in_via_api(student)

      expect(response).to have_http_status(:no_content)
      expect(waitlisted.reload).to be_confirmed
    end

    it "lets an admin cancel any enrollment" do
      enrollment = create(:enrollment, user: student, course: course)

      api_delete "/api/v1/enrollments/#{enrollment.id}", sign_in_via_api(admin)

      expect(response).to have_http_status(:no_content)
      expect(enrollment.reload).to be_cancelled
    end
  end

  describe "POST /api/v1/enrollments/:id/renew" do
    it "renews the enrollment into a new course carrying the anamnesis" do
      enrollment = create(:enrollment,
                          user: student, course: course,
                          heart_problem: false, other_reasons: true)
      other_course = create(:course, :nursing, user: instructor)

      api_post "/api/v1/enrollments/#{enrollment.id}/renew",
               { course_id: other_course.id }, sign_in_via_api(student)

      expect(response).to have_http_status(:created)
      data = json_payload["data"]
      expect(data.dig("course", "id")).to eq(other_course.id)
      expect(data["renewed_from_enrollment_id"]).to eq(enrollment.id)
      expect(data["other_reasons"]).to eq(true)
    end

    it "allows renewing within the same course" do
      enrollment = create(:enrollment, user: student, course: course)

      api_post "/api/v1/enrollments/#{enrollment.id}/renew", {}, sign_in_via_api(student)

      expect(response).to have_http_status(:created)
      expect(json_payload.dig("data", "course", "id")).to eq(course.id)
    end

    it "forbids renewing another student's enrollment" do
      enrollment = create(:enrollment, course: course)

      api_post "/api/v1/enrollments/#{enrollment.id}/renew", { course_id: course.id },
               sign_in_via_api(student)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/enrollments/:id/attendance" do
    let(:enrollment) { create(:enrollment, course: course) }

    it "lets the course instructor mark attendance" do
      api_post "/api/v1/enrollments/#{enrollment.id}/attendance",
               { date: course.start_date.iso8601, present: true },
               sign_in_via_api(instructor)

      expect(response).to have_http_status(:ok)
      expect(json_payload.dig("data", "present")).to eq(true)
      expect(json_payload.dig("data", "date")).to eq(course.start_date.to_date.iso8601)
    end

    it "updates an existing attendance for the same date" do
      create(:attendance, enrollment: enrollment, date: course.start_date.to_date)

      api_post "/api/v1/enrollments/#{enrollment.id}/attendance",
               { date: course.start_date.iso8601, present: false },
               sign_in_via_api(instructor)

      expect(response).to have_http_status(:ok)
      expect(json_payload.dig("data", "present")).to eq(false)
      expect(enrollment.attendances.count).to eq(1)
    end

    it "rejects dates outside the course period" do
      outside = (course.start_date - 10.days).iso8601
      api_post "/api/v1/enrollments/#{enrollment.id}/attendance",
               { date: outside, present: true },
               sign_in_via_api(instructor)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects malformed dates" do
      api_post "/api/v1/enrollments/#{enrollment.id}/attendance",
               { date: "ontem", present: true },
               sign_in_via_api(instructor)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_payload.dig("errors", 0, "code")).to eq("invalid_date")
    end

    it "forbids students from marking attendance" do
      api_post "/api/v1/enrollments/#{enrollment.id}/attendance",
               { date: course.start_date.iso8601, present: true },
               sign_in_via_api(student)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
