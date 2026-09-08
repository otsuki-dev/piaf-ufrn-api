# frozen_string_literal: true

class NotificationMailer < ApplicationMailer
  def notify
    @user = params[:user]
    @body = params[:body]
    subject = params[:subject].presence || t(".subject")

    mail(to: @user.email, subject: subject)
  end
end
