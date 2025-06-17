defmodule AlgoraWeb.Component.NotFoundComponent do
  @moduledoc false
  use AlgoraWeb.Component

  def not_found(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>404 - Page Not Found</title>
        <style>
          * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
          }

          body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
              background: #000;
              color: #fff;
              min-height: 100vh;
              display: flex;
              align-items: center;
              justify-content: center;
              padding: 1rem;
              overflow: hidden;
          }

          .container {
              text-align: center;
              max-width: 500px;
              position: relative;
              z-index: 2;
          }

          .error-code {
              font-size: clamp(4rem, 12vw, 8rem);
              font-weight: 800;
              line-height: 0.9;
              margin-bottom: 1.5rem;
              background: linear-gradient(135deg, #fff 0%, #a0a0a0 100%);
              -webkit-background-clip: text;
              -webkit-text-fill-color: transparent;
              background-clip: text;
              letter-spacing: -0.05em;
              position: relative;
          }

          .error-code::before {
              content: '404';
              position: absolute;
              top: 0;
              left: 0;
              right: 0;
              background: linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%);
              -webkit-background-clip: text;
              -webkit-text-fill-color: transparent;
              background-clip: text;
              filter: blur(2px);
              z-index: -1;
          }

          .title {
              font-size: 1.5rem;
              font-weight: 600;
              margin-bottom: 0.75rem;
              color: #fff;
              letter-spacing: -0.025em;
          }

          .description {
              font-size: 1rem;
              color: #888;
              margin-bottom: 2.5rem;
              line-height: 1.5;
              margin-left: auto;
              margin-right: auto;
          }

          .home-button {
              display: inline-flex;
              align-items: center;
              gap: 0.5rem;
              padding: 0.75rem 1.5rem;
              background: #fff;
              color: #000;
              text-decoration: none;
              border-radius: 0.5rem;
              font-weight: 600;
              font-size: 0.875rem;
              transition: all 0.2s ease;
              border: 2px solid transparent;
              position: relative;
              overflow: hidden;
          }

          .home-button::before {
              content: '';
              position: absolute;
              top: 0;
              left: -100%;
              width: 100%;
              height: 100%;
              background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
              transition: left 0.6s ease;
          }

          .home-button:hover {
              background: #f5f5f5;
              transform: translateY(-1px);
              box-shadow: 0 4px 12px rgba(255,255,255,0.1);
          }

          .home-button:hover::before {
              left: 100%;
          }

          .home-button:active {
              transform: translateY(0);
          }

          .floating-elements {
              position: absolute;
              top: 0;
              left: 0;
              width: 100%;
              height: 100%;
              pointer-events: none;
              z-index: 1;
          }

          .floating-dot {
              position: absolute;
              width: 4px;
              height: 4px;
              background: rgba(255,255,255,0.1);
              border-radius: 50%;
              animation: float 6s ease-in-out infinite;
          }

          .floating-dot:nth-child(1) {
              top: 20%;
              left: 10%;
              animation-delay: 0s;
          }

          .floating-dot:nth-child(2) {
              top: 60%;
              right: 15%;
              animation-delay: 1s;
          }

          .floating-dot:nth-child(3) {
              bottom: 30%;
              left: 20%;
              animation-delay: 2s;
          }

          .floating-dot:nth-child(4) {
              top: 40%;
              right: 30%;
              animation-delay: 3s;
          }

          @keyframes float {
              0%, 100% {
                  transform: translateY(0px) scale(1);
                  opacity: 0;
              }
              50% {
                  transform: translateY(-20px) scale(1.2);
                  opacity: 1;
              }
          }

          .glow {
              position: absolute;
              top: 50%;
              left: 50%;
              transform: translate(-50%, -50%);
              width: 300px;
              height: 300px;
              background: radial-gradient(circle, rgba(255,255,255,0.03) 0%, transparent 70%);
              border-radius: 50%;
              z-index: 1;
          }

          @media (max-width: 640px) {
              .container {
                  max-width: 90%;
              }

              .title {
                  font-size: 1.25rem;
              }

              .description {
                  font-size: 0.875rem;
                  margin-bottom: 2rem;
              }
          }
        </style>
      </head>
      <body>
        <div class="floating-elements">
          <div class="floating-dot"></div>
          <div class="floating-dot"></div>
          <div class="floating-dot"></div>
          <div class="floating-dot"></div>
          <div class="glow"></div>
        </div>

        <div class="container">
          <div class="error-code">404</div>
          <h1 class="title">This page could not be found</h1>
          <p class="description">
            Sorry, the page you're looking for doesn't exist or has been moved.
          </p>
          <.link navigate="/" class="home-button">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M5 12l14 0" /><path d="M5 12l6 6" /><path d="M5 12l6 -6" />
            </svg>
            Go back home
          </.link>
        </div>
      </body>
    </html>
    """
  end
end
