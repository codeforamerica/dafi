class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'

  def basic_message(to:, subject:, body:)
    mail(to: to, subject: subject, body: body) do |format|
      format.text { render plain: textify_html_email(body) }
      format.html { render html: body.html_safe }
    end
  end

  private

  def textify_html_email(body)
    ActionView::Base.full_sanitizer.sanitize(body)
  end
end
