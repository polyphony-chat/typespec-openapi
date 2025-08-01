import "@typespec/http";
import "@typespec/versioning";
import "@typespec/openapi";
import "@typespec/openapi3";
import "../main.tsp";
import "./main.tsp";

using TypeSpec.Http;
using TypeSpec.Versioning;

namespace polyproto.core.Routes.FederatedIdentity {
    @tag("Federated Identity - Registration required")
    @useAuth(BearerAuth)
    namespace Registered {
        /**
         * Request a new ID-Cert, usually done when wanting to authenticate a new session, or after
         * an ID-Cert has been revoked, to re-authenticate a session.
         */
        @route("/idcert")
        @summary("Get a new ID-Cert")
        @added(Version.`v1.0-beta.3`)
        @post
        @tag("Sensitive Actions")
        op newIdCert(
            @doc("Sensitive actions require a second factor of authentication to be executed. Read [section 4.1.2 of the protocol definition](https://docs.polyphony.chat/Protocol%20Specifications/core/#412-sensitive-actions) for more information.")
            @header(#{ name: "X-P2-Sensitive-Solution" })
            sensitiveSolution: string,

            @body csr: string,
        ): {
            @doc("Contains your new ID-Cert in PEM encoding, along with a new session token.")
            @statusCode
            statusCode: 201;

            @body newIdCert: {
                @doc("The generated [ID-Cert](/Protocol%20Specifications/core/#71-home-server-signed-certificates-for-public-client-identity-keys-id-cert) in PEM format.")
                @example("------BEGIN CERTIFICATE------...")
                idCert: string;

                @doc("An authorization secret, called a \"session token\", valid for this `idCert`/session.")
                token: string;
            };
        };

        /**
         * Upload encrypted private key material to the server for later retrieval. The size of
         * the individual array elements must not exceed
         * the server's maximum upload size for this route. This is usually not more than 10kb and can be as
         * low as 800 bytes, depending on the server configuration.
         * @param pkm Array of encrypted private key material objects.
         */
        @route("/session/keymaterial")
        @summary("Upload encrypted private key material")
        @added(Version.`v1.0-beta.3`)
        @post
        op uploadEncryptedPKM(
            @body @minItems(1) pkm: polyproto.core.models.EncryptedPKM[],
        ):
            | {
                  @statusCode statusCode: 201;
              }
            | {
                  @doc("Used, if the `serial_number` does not match any known ID-Cert from this actor.")
                  @statusCode
                  statusCode: 404;
              }
            | {
                  @doc("Status code for when the server already has key material for the given `serial_number`. The client would need to delete the existing key material before uploading new key material.")
                  @statusCode
                  statusCode: 409;
              }
            | {
                  @doc("Uploaded key material exceeds the server's maximum upload size.")
                  @statusCode
                  statusCode: 413;
              };

        /**
         * Retrieve encrypted private key material from the server. The `serial_numbers`, if
         * provided, must match the serial numbers of ID-Certs that the client has uploaded key
         * material for. If no `serial_numbers` are provided, the server will return all key
         * material that the client has uploaded.
         */
        @route("/session/keymaterial")
        @summary("Get encrypted private key material")
        @added(Version.`v1.0-beta.3`)
        @get
        op getEncryptedPKM(@query serials?: uint64[]): {
            @statusCode statusCode: 200;
            @body encryptedPKMs: polyproto.core.models.EncryptedPKM[];
        } | {
            @doc("Returned, if no `serial_numbers` are provided and the client has not uploaded any key material.")
            @statusCode
            statusCode: 204;

            @header(#{ name: "Content-Length" })
            contentLength: 0;
        } | {
            @doc("Returned, if none of the `serial_numbers` match any known ID-Certs from this actor.")
            @statusCode
            statusCode: 404;
        };

        /**
         * Delete encrypted private key material from the server. The `serial_number(s)`, must match
         * the serial numbers of ID-Certs that the client has uploaded key material for.
         */
        @route("/session/keymaterial")
        @tag("Sensitive Actions")
        @summary("Delete encrypted private key material")
        @added(Version.`v1.0-beta.3`)
        @delete
        op deleteEncryptedPKM(
            @doc("Sensitive actions require a second factor of authentication to be executed. Read [section 4.1.2 of the protocol definition](https://docs.polyphony.chat/Protocol%20Specifications/core/#412-sensitive-actions) for more information.")
            @header(#{ name: "X-P2-Sensitive-Solution" })
            sensitiveSolution: string,

            @query serials: uint64[],
        ): {
            @statusCode statusCode: 204;

            @header(#{ name: "Content-Length" })
            contentLength: 0;
        } | {
            @doc("Returned, if none of the `serial_numbers` match any known ID-Certs from this actor.")
            @statusCode
            statusCode: 404;
        };

        /**
         * Retrieve the maximum upload size for encrypted private key material, in bytes.
         *
         * @returns The upload size limit, in bytes.
         */
        @route("/session/keymaterial/size")
        @summary("Get encrypted private key material upload size limit")
        @added(Version.`v1.0-beta.3`)
        @get
        @useAuth(NoAuth)
        op encryptedPKMsizeLimit(): {
            @header(#{ name: "X-MAX-PAYLOAD-SIZE" })
            size: uint32;

            @statusCode statusCode: 200;
        };

        /**
         * Invalidate a session and its' associated ID-Cert by providing the session ID associated
         * with it.
         */
        @route("/session")
        @delete
        @added(Version.`v1.0-beta.3`)
        @summary("Delete/Revoke Session")
        @useAuth(BearerAuth)
        op deleteSession(
            @doc("Sensitive actions require a second factor of authentication to be executed. Read [section 4.1.2 of the protocol definition](https://docs.polyphony.chat/Protocol%20Specifications/core/#412-sensitive-actions) for more information.")
            @header(#{ name: "X-P2-Sensitive-Solution" })
            sensitiveSolution: string,

            @query sessionId: string,
        ): {
            @statusCode statusCode: 204;

            @header(#{ name: "Content-Length" })
            contentLength: 0;
        } | {
            @statusCode statusCode: 404;
        };

        /**
         * Rotate the server's identity key. Requires server administrator permissions.
         * @returns The servers' new ID-Cert, encoded as PEM
         */
        @route("/key/server")
        @summary("Rotate Server Identity Key")
        @added(Version.`v1.0-beta.3`)
        @post
        @useAuth(BearerAuth)
        @tag("Sensitive Actions")
        op name(
            @doc("Sensitive actions require a second factor of authentication to be executed. Read [section 4.1.2 of the protocol definition](https://docs.polyphony.chat/Protocol%20Specifications/core/#412-sensitive-actions) for more information.")
            @header(#{ name: "X-P2-Sensitive-Solution" })
            sensitiveSolution: string,
        ): string;
    }

    @tag("Federated Identity - Registration not required")
    namespace Unregistered {
        /**
         * Request the server's public identity certificate.
         * @returns The current ID-Cert of the server, or, if specified, the ID-Cert the server had
         * at the specified time.
         * @param timestamp An optional UNIX timestamp to retrieve the ID-Cert the server had at that
         * point in time, instead of the current one.
         */
        @route("/idcert/server")
        @get
        @added(Version.`v1.0-beta.3`)
        @summary("Get Server ID-Cert")
        op serverIdCert(
            @query timestamp?: uint64,
        ): polyproto.core.models.CacheableIDCert;

        /**
         * Request the ID-Certs of a specific actor. The specified actor must be registered on this server.
         * @param fid The ID of the actor whose ID-Cert(s) should be returned.
         * @param notBefore: Return only ID-Certs from at or after a specific point in time. UNIX 64 bit timestamp.
         * @param notAfter: Return only ID-Certs from at or before a specific point in time. UNIX 64 bit timestamp.
         * @param sessionId Optionally, return only the ID-Certs matching a specific `sessionId`.
         * @returns JSON-Array of Object(s).
         */
        @route("/idcert/actor")
        @get
        @added(Version.`v1.0-beta.3`)
        @summary("Get Actor ID-Cert(s)")
        op actorCerts(
            @path fid: string,
            @query notBefore?: uint64,
            @query notAfter?: uint64,
            @query sessionId?: string,
        ): {
            @statusCode statusCode: 200;
            @body response: polyproto.core.models.CacheableIDCert[];
        };

        /**
         * Lets a foreign server know that the ID-Cert of a session has changed. This route is also
         * used to inform foreign servers about the revocation of an ID-Cert. The ID-Cert passed as
         * body in this route must belong to the actor making the request.
         * @returns 201 on success, 400 if the body is somehow invalid.
         */
        @route("/session/idcert/extern")
        @put
        @added(Version.`v1.0-beta.3`)
        @useAuth(BearerAuth)
        @summary("Update session ID-Cert")
        op updateSessionCert(@body idCert: string): {
            @statusCode statusCode: 201;
        } | {
            @statusCode statusCode: 400;
        };

        /**
         * Authenticate on a foreign server, creating a session with an authentication token. Requires
         * completing a key trial for the ID-Cert of which the session is supposed to be generated for.
         */
        @route("/session/auth")
        @post
        @added(Version.`v1.0-beta.4`)
        @summary("Authenticate on a foreign server")
        op requestToken(
            @body
            completedChallengeString: polyproto.core.models.KeyTrialCompleted,
        ): {
            @body _: string;
            @statusCode statusCode: 200;
        };

        /**
         * Manually request a KeyTrial, useful for obtaining a session token. Returns
         * a key trial.
         */
        @route("/session/auth")
        @get
        @added(Version.`v1.0-beta.3`)
        @summary("Authenticate on a foreign server")
        op requestChallenge(): {
            @body _: polyproto.core.models.KeyTrial;
            @statusCode statusCode: 200;
        };
    }
}
