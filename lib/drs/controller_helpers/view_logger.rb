# Module for doing very simple impression logging.
# Uses session hash to determine uniqueness, only writes unique views.

module Drs::ControllerHelpers::ViewLogger

  def log_action(action, status, id = nil)
    id ||= params[:id]

    session = request.session_options[:id]
    ip = request.remote_ip
    ref = request.referrer

    DrsImpression.create(pid: id, session_id: session, action: action, ip_address: ip,
                          referrer: ref, status: status)
  end
end
