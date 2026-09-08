# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Courses API", type: :request do
  describe "GET /api/v1/courses" do
    let!(:course) { create(:course) }
    let!(:nursing) { create(:course, :nursing) }

    it "lists courses publicly with pagination metadata" do
      api_get "/api/v1/courses"

      expect(response).to have_http_status(:ok)
      ids = json_payload["data"].map { |c| c["id"] }
      expect(ids).to include(course.id, nursing.id)
      expect(response.headers["X-Total"]).to eq("2")
      expect(json_payload.dig("meta", "pagination", "count")).to eq(2)
    end

    it "filters by modality" do
      api_get "/api/v1/courses", { modality: "natacao" }

      expect(json_payload["data"].map { |c| c["id"] }).to eq([ nursing.id ])
    end

    it "shows status and available slots" do
      api_get "/api/v1/courses"

      expect(json_payload["data"].first).to include("status", "available_slots", "class_time")
    end
  end

  describe "GET /api/v1/courses/:id" do
    let(:course) { create(:course) }

    it "shows the course with counts" do
      api_get "/api/v1/courses/#{course.id}"

      expect(response).to have_http_status(:ok)
      expect(json_payload.dig("data", "id")).to eq(course.id)
      expect(json_payload.dig("data", "confirmed_count")).to eq(0)
      expect(json_payload.dig("data", "waiting_count")).to eq(0)
      expect(json_payload.dig("data", "user", "username")).to eq(course.user.username)
    end
  end

  describe "POST /api/v1/courses" do
    let(:student) { create(:user) }
    let(:instructor) { create(:user, :instructor) }
    let(:admin) { create(:user, :admin) }
    let(:course_params) do
      {
        course: {
          modality: "yoga",
          class_time: "18:00",
          start_date: 1.day.from_now.to_date.iso8601,
          end_date: 90.days.from_now.to_date.iso8601,
          slots: 15
        }
      }
    end

    it "is forbidden for students" do
      api_post "/api/v1/courses", course_params, sign_in_via_api(student)
      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      api_post "/api/v1/courses", course_params
      expect(response).to have_http_status(:unauthorized)
    end

    it "lets admins create courses" do
      api_post "/api/v1/courses", course_params, sign_in_via_api(admin)

      expect(response).to have_http_status(:created)
      expect(json_payload.dig("data", "modality")).to eq("yoga")
      expect(json_payload.dig("data", "user", "username")).to eq(admin.username)
    end

    it "lets instructors create courses assigned to them" do
      api_post "/api/v1/courses", course_params, sign_in_via_api(instructor)

      expect(response).to have_http_status(:created)
      expect(json_payload.dig("data", "user", "id")).to eq(instructor.id)
    end

    it "validates the payload" do
      api_post "/api/v1/courses", { course: { modality: "yoga" } }, sign_in_via_api(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_payload["errors"]).to be_present
    end
  end

  describe "PATCH /api/v1/courses/:id" do
    let(:instructor) { create(:user, :instructor) }
    let(:other_instructor) { create(:user, :instructor) }

    it "lets the owning instructor update the course" do
      course = create(:course, user: instructor)
      api_patch "/api/v1/courses/#{course.id}", { course: { slots: 5 } }, sign_in_via_api(instructor)

      expect(response).to have_http_status(:ok)
      expect(course.reload.slots).to eq(5)
    end

    it "forbids updating another instructor's course" do
      course = create(:course, user: instructor)
      api_patch "/api/v1/courses/#{course.id}", { course: { slots: 5 } }, sign_in_via_api(other_instructor)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/courses/:id" do
    let(:admin) { create(:user, :admin) }

    it "removes a course without enrollments" do
      course = create(:course)
      api_delete "/api/v1/courses/#{course.id}", sign_in_via_api(admin)

      expect(response).to have_http_status(:no_content)
      expect(Course.exists?(course.id)).to be(false)
    end

    it "refuses to remove a course with enrollments" do
      course = create(:course)
      create(:enrollment, course: course)

      api_delete "/api/v1/courses/#{course.id}", sign_in_via_api(admin)

      expect(response).to have_http_status(:conflict)
      expect(json_payload.dig("errors", 0, "code")).to eq("course_has_enrollments")
    end
  end
end
