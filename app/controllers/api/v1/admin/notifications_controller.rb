# frozen_string_literal: true

module Api
  module V1
    module Admin
      class NotificationsController < Api::V1::BaseController
        include Api::V1::AdminOnly

        # POST /api/v1/admin/notifications
        #
        # Body schema:
        #   { subject:, body:, audience: { user_ids: [] } | { role: "students" } |
        #     { enrollment_status: "waitlisted" } | { all: true } }
        #
        # Emails are enqueued asynchronously via Delayed Job.
        def create
          recipients = resolve_recipients

          if recipients.none?
            render_error :unprocessable_content, code: "no_recipients",
                                                title: I18n.t("errors.no_recipients")
            return
          end

          recipients.find_each do |recipient|
            NotificationMailer.with(user: recipient, subject: params[:subject], body: params[:body])
                              .notify
                              .deliver_later
          end

          render json: {
            data: {
              recipients_count: recipients.size,
              message: I18n.t("admin.notifications.enqueued")
            }
          }, status: :accepted
        end

        private

        def resolve_recipients
          audience = params.fetch(:audience, params)
          if audience[:user_ids].present?
            User.where(id: audience[:user_ids]).confirmed_accounts
          elsif audience[:role].present?
            role_scope(audience[:role])
          elsif audience[:enrollment_status].present?
            User.joins(:enrollments)
                .where(enrollments: { status: audience[:enrollment_status] }).distinct
          elsif audience[:all].present?
            User.confirmed_accounts.all
          else
            User.none
          end
        end

        def role_scope(role)
          case role.to_s
          when "students" then User.students.confirmed_accounts
          when "instructors" then User.instructors.confirmed_accounts
          when "admins" then User.admins.confirmed_accounts
          else User.none
          end
        end
      end
    end
  end
end
