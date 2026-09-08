# frozen_string_literal: true

namespace :scheduled do
  desc "Expira inscrições pendentes não confirmadas (default: mais de 7 dias)"
  task expire_pending_enrollments: :environment do
    ExpirePendingEnrollmentsJob.perform_later
  end

  desc "Desativa alunos sem presença recente (default: últimos 14 dias)"
  task deactivate_inactive_students: :environment do
    InactiveStudentsJob.perform_later
  end

  desc "Manutenção diária (limpeza da denylist de JWT)"
  task maintenance: :environment do
    DailyMaintenanceJob.perform_later
  end
end
