class AppleAssociationsController < ApplicationController
  def show
    render json: {
      applinks: {
        details: [
          {
            appID: "#{ENV.fetch('APPLE_TEAM_ID')}.uk.co.bookpilot.app",
            paths: [
              "/password/edit",
              "/password/edit/*"
            ]
          }
        ]
      }
    }
  end
end