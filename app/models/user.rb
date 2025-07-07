class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :user_exams, dependent: :destroy
  has_many :exams, through: :user_exams

  VALID_ROLES = %w[admin student]
  validates :role, presence: true, inclusion: { in: VALID_ROLES }


  def admin?
    role == 'admin'
  end

  def student?
    role == 'student'
  end

end
