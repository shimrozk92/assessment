class User < ApplicationRecord
  has_many :enrollments
  has_many :programs, through: :enrollments
  has_many :teachers, through: :enrollments, source: :teacher

  enum kind: { student: 0, teacher: 1, student_teacher: 2 }

  validates :name, presence: true

  validate :validate_user_kind

  scope :favorites, -> {
    includes(:enrollments)
      .where(enrollments: { favorite: true })
  }

  def self.classmates(user)
    joins(enrollments: :program)
      .where(enrollments: { program_id: user.enrollments.select(:program_id) })
      .where.not(id: user.id)
      .distinct
  end

  private

  def validate_user_kind
    return unless kind_changed?

    if student? && Enrollment.where(teacher: self).exists?
      errors.add(:kind, "can not be student because is teaching in at least one program")
    elsif teacher? && enrollments.exists?
      errors.add(:kind, "can not be teacher because is studying in at least one program")
    end
  end
end
