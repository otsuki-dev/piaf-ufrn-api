# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin API", type: :request do
  let(:student) { create(:user) }
  let(:admin) { create(:user, :admin) }

  describe "GET /api/v1/admin/stats" do
    before { create(:enrollment, course: create(:course)) }

    it "requires admin" do
      api_get "/api/v1/admin/stats", {}, sign_in_via_api(student)
      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      api_get "/api/v1/admin/stats"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns aggregate counters" do
      api_get "/api/v1/admin/stats", {}, sign_in_via_api(admin)

      expect(response).to have_http_status(:ok)
      data = json_payload["data"]
      expect(data["users"]).to include("total", "admins", "instructors", "students", "confirmed")
      expect(data["courses"]).to include("total", "active", "by_modality")
      expect(data["enrollments"]).to include("total", "by_status", "waitlist", "confirmed")
      expect(data["attendance"]).to include("registered_today", "registered_this_week")
    end
  end

  describe "GET /api/v1/admin/reports" do
    it "is forbidden for non admins" do
      api_get "/api/v1/admin/reports", {}, sign_in_via_api(student)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns the per-course report and the summary" do
      course = create(:course, slots: 2)
      confirmed = create(:enrollment, course: course)
      create(:enrollment, :waitlisted, course: course)
      create(:attendance, enrollment: confirmed, date: course.start_date.to_date)

      api_get "/api/v1/admin/reports", {}, sign_in_via_api(admin)

      expect(response).to have_http_status(:ok)
      data = json_payload["data"]
      course_data = data["courses"].first
      expect(course_data).to include(
        "course_id" => course.id,
        "modality" => course.modality,
        "slots" => 2,
        "confirmed" => 1,
        "waitlisted" => 1,
        "occupation_rate" => 50.0,
        "evasion_rate" => 0.0,
        "attendance_rate" => 100.0
      )
      expect(data["summary"]).to include("total_courses" => 1, "active_courses" => 1)
    end
  end

  describe "POST /api/v1/admin/notifications" do
    let(:target) { create(:user) }

    it "enqueues emails for the chosen user ids" do
      api_post "/api/v1/admin/notifications", {
        subject: "Manutenção da piscina",
        body: "A piscina estará fechada no sábado.",
        audience: { user_ids: [ target.id ] }
      }, sign_in_via_api(admin)

      expect(response).to have_http_status(:accepted)
      expect(json_payload.dig("data", "recipients_count")).to eq(1)
      expect(enqueued_jobs.size).to eq(1)
      expect(enqueued_jobs.first[:args].first).to eq("NotificationMailer")
    end

    it "supports a role audience" do
      student
      unconfirmed_student = create(:user, :unconfirmed)
      api_post "/api/v1/admin/notifications", {
        subject: "Nova grade",
        body: "Confira as novas turmas.",
        audience: { role: "students" }
      }, sign_in_via_api(admin)

      expect(response).to have_http_status(:accepted)
      expect(json_payload.dig("data", "recipients_count")).to eq(1)
    end

    it "rejects audiences without recipients" do
      api_post "/api/v1/admin/notifications", {
        subject: "Teste",
        body: "Ninguém.",
        audience: { user_ids: [ 999_999 ] }
      }, sign_in_via_api(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_payload.dig("errors", 0, "code")).to eq("no_recipients")
    end
  end

  describe "POST /api/v1/admin/students/:id/deactivate" do
    it "deactivates the student enrollments and promotes the waitlist" do
      course = create(:course, slots: 1)
      no_show = create(:enrollment, course: course)
      waitlisted = create(:enrollment, :waitlisted, course: course)

      api_post "/api/v1/admin/students/#{no_show.user_id}/deactivate", {}, sign_in_via_api(admin)

      expect(response).to have_http_status(:ok)
      expect(json_payload.dig("data", "deactivated_count")).to eq(1)
      expect(no_show.reload).to be_inactive
      expect(waitlisted.reload).to be_confirmed
    end
  end
end
