defmodule AlgoraWeb.Legal.TermsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <main class="h-full overflow-auto">
        <article class="prose mx-auto py-24 dark:prose-invert lg:prose-lg">
          <h1>
            <span>TERMS OF SERVICE</span>
          </h1>

          <div>
            <span>Last updated:&nbsp;08/17/2021</span>
          </div>

          <ol class="list-none pl-0" start={1}>
            <li>
              <span>Introduction</span>
            </li>
          </ol>
          <div>
            <span>Welcome to&nbsp;</span>
            <span>Algora, PBC.</span>
            <span>&nbsp;(“</span>
            <span>Company</span>
            <span>”, “</span>
            <span>we</span>
            <span>”, “</span>
            <span>our</span>
            <span>”, “</span>
            <span>us</span>
            <span>”)</span>
            <span>
              ! As you have just clicked our Terms of Service, please pause,
              grab a cup of coffee and carefully read the following pages. It
              will take you approximately 20&nbsp;minutes.
            </span>
          </div>

          <div>
            <span>These Terms of Service (“</span>
            <span>Terms</span>
            <span>”, “</span>
            <span>Terms of Service</span>
            <span>
              ”) govern your use of&nbsp;our web pages located at {AlgoraWeb.Endpoint.url()}
            </span>
            <span>&nbsp;operated by&nbsp;Algora, PBC.</span>
          </div>

          <div>
            <span>
              Our Privacy Policy also governs your use of our Service and
              explains how we collect, safeguard and disclose information that
              results from your use of our web pages. Please read it here {AlgoraWeb.Endpoint.url()}/legal/privacy .
            </span>
          </div>

          <div>
            <span>
              Your agreement with us includes these Terms&nbsp;and our Privacy
              Policy&nbsp;(“
            </span>
            <span>Agreements</span>
            <span>
              ”). You acknowledge that you have read and understood Agreements,
              and agree to be bound of them.
            </span>
          </div>

          <div>
            <span>
              If you do not agree with (or cannot comply with) Agreements, then
              you may not use the Service, but please let us know by emailing at
              ioannis@algora.io so we can try to find a solution. These Terms
              apply to all visitors, users and others who wish to access or use
              Service.
            </span>
          </div>

          <div>
            <span>Thank you for being responsible.</span>
          </div>

          <ol class="list-none pl-0" start={2}>
            <li>
              <span>Communications</span>
            </li>
          </ol>
          <div>
            <span>
              By creating an Account on our Service, you agree to subscribe to
              newsletters, marketing or promotional materials and other
              information we may send. However, you may opt out of receiving
              any, or all, of these communications from us by following the
              unsubscribe link or by emailing at.
            </span>
          </div>

          <ol class="list-none pl-0" start={3}>
            <li>
              <span>Purchases</span>
            </li>
          </ol>
          <div>
            <span>
              If you wish to purchase any product or service made available
              through Service (“
            </span>
            <span>Purchase</span>
            <span>
              ”), you may be asked to supply certain information relevant to
              your Purchase including, without limitation, your credit card
              number, the expiration date of your credit card, your billing
              address, and your shipping information.
            </span>
          </div>

          <div>
            <span>
              You represent and warrant that: (i) you have the legal right to
              use any credit card(s) or other payment method(s) in connection
              with any Purchase; and that (ii) the information you supply to us
              is true, correct and complete.
            </span>
          </div>

          <div>
            <span>
              We may employ the use of third party services for the purpose of
              facilitating payment and the completion of Purchases. By
              submitting your information, you grant us the right to provide the
              information to these third parties&nbsp;subject to our Privacy
              Policy.
            </span>
          </div>

          <div>
            <span>
              We reserve the right to refuse or cancel your order at any time
              for reasons including but not limited to: product or service
              availability, errors in the description or price of the product or
              service, error in your order or other reasons.
            </span>
          </div>

          <div>
            <span>
              We reserve the right to refuse or cancel your order if fraud or an
              unauthorized or illegal transaction is suspected.{" "}
            </span>
          </div>

          <ol class="list-none pl-0" start={4}>
            <li>
              <span>Contests, Sweepstakes and Promotions</span>
            </li>
          </ol>
          <div>
            <span>
              Any contests, sweepstakes or other promotions (collectively, “
            </span>
            <span>Promotions</span>
            <span>
              ”) made available through Service may be governed by rules that
              are separate from these Terms of Service. If you participate in
              any Promotions, please review the applicable rules&nbsp;as well as
              our Privacy Policy. If the rules for a Promotion conflict with
              these Terms of Service, Promotion rules will apply.
            </span>
          </div>

          <ol class="list-none pl-0" start={5}>
            <li>
              <span>Fee Changes</span>
            </li>
          </ol>
          <div>
            <span>
              Algora, PBC., in its sole discretion and at any time, may modify
              Subscription fees for the Subscriptions. Any Subscription fee
              change will become effective at the end of the then-current
              Billing Cycle.
            </span>
          </div>

          <div>
            <span>
              Algora, PBC.&nbsp;will provide you with a reasonable prior notice
              of any change in Subscription fees to give you an opportunity to
              terminate your Subscription before such change becomes effective.
            </span>
          </div>

          <div>
            <span>
              Your continued use of Service after Subscription fee change comes
              into effect constitutes your agreement to pay the modified
              Subscription fee amount.
            </span>
          </div>

          <ol class="list-none pl-0" start={6}>
            <li>
              <span>Refunds</span>
            </li>
          </ol>
          <div>
            <span>
              Except when required by law, paid Subscription fees are
              non-refundable.
            </span>
          </div>

          <ol class="list-none pl-0" start={7}>
            <li>
              <span>Content</span>
            </li>
          </ol>
          <div>
            <span>
              Our Service allows you to post, link, store, share and otherwise
              make available certain information, text, graphics, videos, or
              other material (“
            </span>
            <span>Content</span>
            <span>
              ”). You are responsible for Content that you post on or through
              Service, including its legality, reliability, and appropriateness.
            </span>
          </div>

          <div>
            <span>
              By posting Content on or through Service, You represent and
              warrant that: (i) Content is yours (you own it) and/or you have
              the right to use it and the right to grant us the rights and
              license as provided in these Terms, and (ii) that the posting of
              your Content on or through Service does not violate the privacy
              rights, publicity rights, copyrights, contract rights or any other
              rights of any person or entity. We reserve the right to terminate
              the account of anyone found to be infringing on a copyright.
            </span>
          </div>

          <div>
            <span>
              You retain any and all of your rights to any Content you submit,
              post or display on or through Service and you are responsible for
              protecting those rights. We take no responsibility and assume no
              liability for Content you or any third party posts on or through
              Service. However, by posting Content using Service you grant us
              the right and license to use, modify, publicly perform, publicly
              display, reproduce, and distribute such Content on and through
              Service. You agree that this license includes the right for us to
              make your Content available to other users of Service, who may
              also use your Content subject to these Terms.
            </span>
          </div>

          <div>
            <span>
              Algora, PBC.&nbsp;has the right but not the obligation to monitor
              and edit all Content provided by users.
            </span>
          </div>

          <div>
            <span>
              In addition, Content found on or through this Service are the
              property of&nbsp;Algora, PBC.&nbsp;or used with permission. You
              may not distribute, modify, transmit, reuse, download, repost,
              copy, or use said Content, whether in whole or in part, for
              commercial purposes or for personal gain, without express advance
              written permission from us.
            </span>
          </div>

          <ol class="list-none pl-0" start={8}>
            <li>
              <span>Prohibited Uses</span>
            </li>
          </ol>
          <div>
            <span>
              You may use Service only for lawful purposes and in accordance
              with Terms. You agree not to use Service:
            </span>
          </div>

          <ol class="list-none pl-0" start={1}>
            <li>
              <span>
                In any way that violates any applicable national or
                international law or regulation.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={2}>
            <li>
              <span>
                For the purpose of exploiting, harming, or attempting to exploit
                or harm minors in any way by exposing them to inappropriate
                content or otherwise.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={3}>
            <li>
              <span>
                To transmit, or procure the sending of, any advertising or
                promotional material, including any “junk mail”, “chain letter,”
                “spam,” or any other similar solicitation.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={4}>
            <li>
              <span>
                To impersonate or attempt to impersonate Company, a Company
                employee, another user, or any other person or entity.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={5}>
            <li>
              <span>
                In any way that infringes upon the rights of others, or in any
                way is illegal, threatening, fraudulent, or harmful, or in
                connection with any unlawful, illegal, fraudulent, or harmful
                purpose or activity.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={6}>
            <li>
              <span>
                To engage in any other conduct that restricts or inhibits
                anyone’s use or enjoyment of Service, or which, as determined by
                us, may harm or offend Company or users of Service or expose
                them to liability.
              </span>
            </li>
          </ol>

          <div>
            <span>Additionally, you agree not to:</span>
          </div>

          <ol class="list-none pl-0" start={1}>
            <li>
              <span>
                Use Service in any manner that could disable, overburden,
                damage, or impair Service or interfere with any other party’s
                use of Service, including their ability to engage in real time
                activities through Service.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={2}>
            <li>
              <span>
                Use any robot, spider, or other automatic device, process, or
                means to access Service for any purpose, including monitoring or
                copying any of the material on Service.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={3}>
            <li>
              <span>
                Use any manual process to monitor or copy any of the material on
                Service or for any other unauthorized purpose without our prior
                written consent.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={4}>
            <li>
              <span>
                Use any device, software, or routine that interferes with the
                proper working of Service.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={5}>
            <li>
              <span>
                Introduce any viruses, trojan horses, worms, logic bombs, or
                other material which is maliIOus or technologically harmful.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={6}>
            <li>
              <span>
                Attempt to gain unauthorized access to, interfere with, damage,
                or disrupt any parts of Service, the server on which Service is
                stored, or any server, computer, or database connected to
                Service.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={7}>
            <li>
              <span>
                Attack Service via a denial-of-service attack or a distributed
                denial-of-service attack.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={8}>
            <li>
              <span>
                Take any action that may damage or falsify Company rating.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={9}>
            <li>
              <span>
                Otherwise attempt to interfere with the proper working of
                Service.
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={9}>
            <li>
              <span>No Use By Minors</span>
            </li>
          </ol>
          <div>
            <span>
              Service is intended only for access and use by individuals at
              least eighteen (18) years old. By accessing or using any of
              Company, you warrant and represent that you are at least eighteen
              (18) years of age and with the full authority, right, and capacity
              to enter into this agreement and abide by all of the terms and
              conditions of Terms. If you are not at least eighteen (18) years
              old, you are prohibited from both the access and usage of Service.
            </span>
          </div>

          <ol class="list-none pl-0" start={10}>
            <li>
              <span>Accounts</span>
            </li>
          </ol>
          <div>
            <span>
              When you create an account with us, you guarantee that you are
              above the age of 18, and that the information you provide us is
              accurate, complete, and current at all times. Inaccurate,
              incomplete, or obsolete information may result in the immediate
              termination of your account on Service.
            </span>
          </div>

          <div>
            <span>
              You are responsible for maintaining the confidentiality of your
              account and password, including but not limited to the restriction
              of access to your computer and/or account. You agree to accept
              responsibility for any and all activities or actions that occur
              under your account and/or password, whether your password is with
              our Service or a third-party service. You must notify us
              immediately upon becoming aware of any breach of security or
              unauthorized use of your account.
            </span>
          </div>

          <div>
            <span>
              You may not use as a username the name of another person or entity
              or that is not lawfully available for use, a name or trademark
              that is subject to any rights of another person or entity other
              than you, without appropriate authorization. You may not use as a
              username any name that is offensive, vulgar or obscene.
            </span>
          </div>

          <div>
            <span>
              We reserve the right to refuse service, terminate accounts, remove
              or edit content, or cancel orders in our sole discretion.
            </span>
          </div>

          <ol class="list-none pl-0" start={11}>
            <li>
              <span>Intellectual Property</span>
            </li>
          </ol>
          <div>
            <span>
              Service and its original content (excluding Content provided by
              users), features and functionality are and will remain the
              exclusive property of&nbsp;Algora, PBC.&nbsp;and its licensors.
              Service is protected by copyright, trademark, and other laws
              of&nbsp;the United States and foreign countries. Our trademarks
              and trade dress may not be used in connection with any product or
              service without the prior written consent of&nbsp;Algora, PBC..
            </span>
          </div>

          <ol class="list-none pl-0" start={12}>
            <li>
              <span>Copyright Policy</span>
            </li>
          </ol>
          <div>
            <span>
              We respect the intellectual property rights of others. It is our
              policy to respond to any claim that Content posted on Service
              infringes on the copyright or other intellectual property rights
              (“
            </span>
            <span>Infringement</span>
            <span>”) of any person or entity.</span>
          </div>

          <div>
            <span>
              If you are a copyright owner, or authorized on behalf of one, and
              you believe that the copyrighted work has been copied in a way
              that constitutes copyright infringement, please submit your claim
              via email to&nbsp;ioannis@algora.io, with the subject line:
              “Copyright Infringement” and include in your claim a detailed
              description of the alleged Infringement as detailed below, under
              “DMCA Notice and Procedure for Copyright Infringement Claims”
            </span>
          </div>

          <div>
            <span>
              You may be held accountable for damages (including costs and
              attorneys&apos; fees) for misrepresentation or bad-faith claims on
              the infringement of any Content found on and/or through Service on
              your copyright.
            </span>
          </div>

          <ol class="list-none pl-0" start={13}>
            <li>
              <span>
                DMCA Notice and Procedure for Copyright Infringement Claims
              </span>
            </li>
          </ol>
          <div>
            <span>
              You may submit a notification pursuant to the Digital Millennium
              Copyright Act (DMCA) by providing our Copyright Agent with the
              following information in writing (see 17 U.S.C 512(c)(3) for
              further detail):
            </span>
          </div>

          <ol class="list-none pl-0" start={1}>
            <li>
              <span>
                an electronic or physical signature of the person authorized to
                act on behalf of the owner of the copyright&apos;s interest;
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={2}>
            <li>
              <span>
                a description of the copyrighted work that you claim has been
                infringed, including the URL (i.e., web page address) of the
                location where the copyrighted work exists or a copy of the
                copyrighted work;
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={3}>
            <li>
              <span>
                identification of the URL or other specific location on Service
                where the material that you claim is infringing is located;
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={4}>
            <li>
              <span>your address, telephone number, and email address;</span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={5}>
            <li>
              <span>
                a statement by you that you have a good faith belief that the
                disputed use is not authorized by the copyright owner, its
                agent, or the law;
              </span>
            </li>
          </ol>

          <ol class="list-none pl-0" start={6}>
            <li>
              <span>
                a statement by you, made under penalty of perjury, that the
                above information in your notice is accurate and that you are
                the copyright owner or authorized to act on the copyright
                owner&apos;s behalf.
              </span>
            </li>
          </ol>

          <div>
            <span>
              You can contact our Copyright Agent via email
              at&nbsp;ioannis@algora.io
            </span>
          </div>

          <ol class="list-none pl-0" start={14}>
            <li>
              <span>Error Reporting and Feedback</span>
            </li>
          </ol>
          <div>
            <span>
              You may provide us&nbsp;directly at ioannis@algora.io&nbsp;with
              information and feedback concerning errors, suggestions for
              improvements, ideas, problems, complaints, and other matters
              related to our Service (“
            </span>
            <span>Feedback</span>
            <span>
              ”). You acknowledge and agree that: (i) you shall not retain,
              acquire or assert any intellectual property right or other right,
              title or interest in or to the Feedback; (ii) Company may have
              development ideas similar to the Feedback; (iii) Feedback does not
              contain confidential information or proprietary information from
              you or any third party; and (iv) Company is not under any
              obligation of confidentiality with respect to the Feedback. In the
              event the transfer of the ownership to the Feedback is not
              possible due to applicable mandatory laws, you grant Company and
              its affiliates an exclusive, transferable, irrevocable,
              free-of-charge, sub-licensable, unlimited and perpetual right to
              use (including copy, modify, create derivative works, publish,
              distribute and commercialize) Feedback in any manner and for any
              purpose.
            </span>
          </div>

          <ol class="list-none pl-0" start={15}>
            <li>
              <span>Links To Other Web Sites</span>
            </li>
          </ol>
          <div>
            <span>
              Our Service may contain links to third party web sites or services
              that are not owned or controlled by&nbsp;Algora, PBC.
            </span>
          </div>

          <div>
            <span>
              Algora, PBC.&nbsp;has no control over, and assumes no
              responsibility for the content, privacy policies, or practices of
              any third party web sites or services. We do not warrant the
              offerings of any of these entities/individuals or their websites.
            </span>
          </div>

          <div>
            <span>YOU ACKNOWLEDGE AND AGREE THAT&nbsp;</span>
            <span>ALGORA, PBC.</span>

            <span>
              SHALL NOT BE RESPONSIBLE OR LIABLE, DIRECTLY OR INDIRECTLY, FOR
              ANY DAMAGE OR LOSS CAUSED OR ALLEGED TO BE CAUSED BY OR IN
              CONNECTION WITH USE OF OR RELIANCE ON ANY SUCH CONTENT, GOODS OR
              SERVICES AVAILABLE ON OR THROUGH ANY SUCH THIRD PARTY WEB SITES OR
              SERVICES.
            </span>
          </div>

          <div>
            <span>
              WE STRONGLY ADVISE YOU TO READ THE TERMS OF SERVICE AND PRIVACY
              POLICIES OF ANY THIRD PARTY WEB SITES OR SERVICES THAT YOU VISIT.
            </span>
          </div>

          <ol class="list-none pl-0" start={16}>
            <li>
              <span>Disclaimer Of Warranty </span>
            </li>
          </ol>
          <div>
            <span>
              THESE SERVICES ARE PROVIDED BY COMPANY ON AN “AS IS” AND “AS
              AVAILABLE” BASIS. COMPANY MAKES NO REPRESENTATIONS OR WARRANTIES
              OF ANY KIND, EXPRESS OR IMPLIED, AS TO THE OPERATION OF THEIR
              SERVICES, OR THE INFORMATION, CONTENT OR MATERIALS INCLUDED
              THEREIN. YOU EXPRESSLY AGREE THAT YOUR USE OF THESE SERVICES,
              THEIR CONTENT, AND ANY SERVICES OR ITEMS OBTAINED FROM US IS AT
              YOUR SOLE RISK.
            </span>
          </div>

          <div>
            <span>
              NEITHER COMPANY NOR ANY PERSON ASSOCIATED WITH COMPANY MAKES ANY
              WARRANTY OR REPRESENTATION WITH RESPECT TO THE COMPLETENESS,
              SECURITY, RELIABILITY, QUALITY, ACCURACY, OR AVAILABILITY OF THE
              SERVICES. WITHOUT LIMITING THE FOREGOING, NEITHER COMPANY NOR
              ANYONE ASSOCIATED WITH COMPANY REPRESENTS OR WARRANTS THAT THE
              SERVICES, THEIR CONTENT, OR ANY SERVICES OR ITEMS OBTAINED THROUGH
              THE SERVICES WILL BE ACCURATE, RELIABLE, ERROR-FREE, OR
              UNINTERRUPTED, THAT DEFECTS WILL BE CORRECTED, THAT THE SERVICES
              OR THE SERVER THAT MAKES IT AVAILABLE ARE FREE OF VIRUSES OR OTHER
              HARMFUL COMPONENTS OR THAT THE SERVICES OR ANY SERVICES OR ITEMS
              OBTAINED THROUGH THE SERVICES WILL OTHERWISE MEET YOUR NEEDS OR
              EXPECTATIONS.
            </span>
          </div>

          <div>
            <span>
              COMPANY HEREBY DISCLAIMS ALL WARRANTIES OF ANY KIND, WHETHER
              EXPRESS OR IMPLIED, STATUTORY, OR OTHERWISE, INCLUDING BUT NOT
              LIMITED TO ANY WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT,
              AND FITNESS FOR PARTICULAR PURPOSE.
            </span>
          </div>

          <div>
            <span>
              THE FOREGOING DOES NOT AFFECT ANY WARRANTIES WHICH CANNOT BE
              EXCLUDED OR LIMITED UNDER APPLICABLE LAW.
            </span>
          </div>

          <ol class="list-none pl-0" start={17}>
            <li>
              <span>Limitation Of Liability</span>
            </li>
          </ol>
          <div>
            <span>
              EXCEPT AS PROHIBITED BY LAW, YOU WILL HOLD US AND OUR OFFICERS,
              DIRECTORS, EMPLOYEES, AND AGENTS HARMLESS FOR ANY INDIRECT,
              PUNITIVE, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGE, HOWEVER IT
              ARISES (INCLUDING ATTORNEYS&apos; FEES AND ALL RELATED COSTS AND
              EXPENSES OF LITIGATION AND ARBITRATION, OR AT TRIAL OR ON APPEAL,
              IF ANY, WHETHER OR NOT LITIGATION OR ARBITRATION IS INSTITUTED),
              WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE, OR OTHER TORTIOUS
              ACTION, OR ARISING OUT OF OR IN CONNECTION WITH THIS AGREEMENT,
              INCLUDING WITHOUT LIMITATION ANY CLAIM FOR PERSONAL INJURY OR
              PROPERTY DAMAGE, ARISING FROM THIS AGREEMENT AND ANY VIOLATION BY
              YOU OF ANY FEDERAL, STATE, OR LOCAL LAWS, STATUTES, RULES, OR
              REGULATIONS, EVEN IF COMPANY HAS BEEN PREVIOUSLY ADVISED OF THE
              POSSIBILITY OF SUCH DAMAGE. EXCEPT AS PROHIBITED BY LAW, IF THERE
              IS LIABILITY FOUND ON THE PART OF COMPANY, IT WILL BE LIMITED TO
              THE AMOUNT PAID FOR THE PRODUCTS AND/OR SERVICES, AND UNDER NO
              CIRCUMSTANCES WILL THERE BE CONSEQUENTIAL OR PUNITIVE DAMAGES.
              SOME STATES DO NOT ALLOW THE EXCLUSION OR LIMITATION OF PUNITIVE,
              INCIDENTAL OR CONSEQUENTIAL DAMAGES, SO THE PRIOR LIMITATION OR
              EXCLUSION MAY NOT APPLY TO YOU.
            </span>
          </div>

          <ol class="list-none pl-0" start={18}>
            <li>
              <span>Termination</span>
            </li>
          </ol>
          <div>
            <span>
              We may terminate or suspend your account and bar access to Service
              immediately, without prior notice or liability, under our sole
              discretion, for any reason whatsoever and without limitation,
              including but not limited to a breach of Terms.
            </span>
          </div>

          <div>
            <span>
              If you wish to terminate your account, you may simply discontinue
              using Service.
            </span>
          </div>

          <div>
            <span>
              All provisions of Terms which by their nature should survive
              termination shall survive termination, including, without
              limitation, ownership provisions, warranty disclaimers, indemnity
              and limitations of liability.
            </span>
          </div>

          <ol class="list-none pl-0" start={19}>
            <li>
              <span>Governing Law</span>
            </li>
          </ol>
          <div>
            <span>
              These Terms shall be governed and construed in accordance with the
              laws of&nbsp;State of Delaware&nbsp;without regard to its conflict
              of law provisions.
            </span>
          </div>

          <div>
            <span>
              Our failure to enforce any right or provision of these Terms will
              not be considered a waiver of those rights. If any provision of
              these Terms is held to be invalid or unenforceable by a court, the
              remaining provisions of these Terms will remain in effect. These
              Terms constitute the entire agreement between us regarding our
              Service and supersede and replace any prior agreements we might
              have had between us regarding Service.
            </span>
          </div>

          <ol class="list-none pl-0" start={20}>
            <li>
              <span>Changes To Service</span>
            </li>
          </ol>
          <div>
            <span>
              We reserve the right to withdraw or amend our Service, and any
              service or material we provide via Service, in our sole discretion
              without notice. We will not be liable if for any reason all or any
              part of Service is unavailable at any time or for any period. From
              time to time, we may restrict access to some parts of Service, or
              the entire Service, to users, including registered users.
            </span>
          </div>

          <ol class="list-none pl-0" start={21}>
            <li>
              <span>Amendments To Terms</span>
            </li>
          </ol>
          <div>
            <span>
              We may amend Terms at any time by posting the amended terms on
              this site. It is your responsibility to review these Terms
              periodically.
            </span>
          </div>

          <div>
            <span>
              Your continued use of the Platform following the posting of
              revised Terms means that you accept and agree to the changes. You
              are expected to check this page frequently so you are aware of any
              changes, as they are binding on you.
            </span>
          </div>

          <div>
            <span>
              By continuing to access or use our Service after any revisions
              become effective, you agree to be bound by the revised terms. If
              you do not agree to the new terms, you are no longer authorized to
              use Service.
            </span>
          </div>

          <ol class="list-none pl-0" start={22}>
            <li>
              <span>Waiver And Severability</span>
            </li>
          </ol>
          <div>
            <span>
              No waiver by Company of any term or condition set forth in Terms
              shall be deemed a further or continuing waiver of such term or
              condition or a waiver of any other term or condition, and any
              failure of Company to assert a right or provision under Terms
              shall not constitute a waiver of such right or provision.
            </span>
          </div>

          <div>
            <span>
              If any provision of Terms is held by a court or other tribunal of
              competent jurisdiction to be invalid, illegal or unenforceable for
              any reason, such provision shall be eliminated or limited to the
              minimum extent such that the remaining provisions of Terms will
              continue in full force and effect.
            </span>
          </div>

          <ol class="list-none pl-0" start={23}>
            <li>
              <span>Acknowledgement</span>
            </li>
          </ol>
          <div>
            <span>
              BY USING SERVICE OR OTHER SERVICES PROVIDED BY US, YOU ACKNOWLEDGE
              THAT YOU HAVE READ THESE TERMS OF SERVICE AND AGREE TO BE BOUND BY
              THEM.
            </span>
          </div>

          <ol class="list-none pl-0" start={24}>
            <li>
              <span>Contact Us</span>
            </li>
          </ol>
          <div>
            <span>
              Please send your feedback, comments, requests for technical
              support:
            </span>
          </div>
          <div>
            <span>By email: ioannis@algora.io.</span>
          </div>
        </article>
      </main>
    </div>
    """
  end
end
