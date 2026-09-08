# frozen_string_literal: true

class EnrollmentMailer < ApplicationMailer
  before_action :load_enrollment

  def confirmed
    mail(to: @enrollment.user.email,
         subject: t(".subject", modality: @course.modality_label))
  end

  def waitlisted
    mail(to: @enrollment.user.email,
         subject: t(".subject", modality: @course.modality_label))
  end

  def waitlist_promoted
    mail(to: @enrollment.user.email,
         subject: t(".subject", modality: @course.modality_label))
  end

  def cancelled
    mail(to: @enrollment.user.email,
         subject: t(".subject", modality: @course.modality_label))
  end

  def inactive
    mail(to: @enrollment.user.email,
         subject: t(".subject"))
  end

  private

  def load_enrollment
    @enrollment = params[:enrollment]
    @course = @enrollment.course
    @student = @enrollment.user
  end
end
