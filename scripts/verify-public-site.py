"""Smoke the assembled landing + Astro site over HTTP, without dependencies."""

import sys
from html.parser import HTMLParser
from urllib.error import HTTPError
from urllib.parse import unquote, urldefrag, urljoin, urlsplit
from urllib.request import HTTPRedirectHandler, build_opener


class Redirects(HTTPRedirectHandler):
    # macOS Python 3.9 does not follow Caddy's canonical 308 redirect.
    # This verifier sends GET only, so 301 has the same redirect semantics.
    def http_error_308(self, request, response, code, message, headers):
        return self.http_error_301(request, response, 301, message, headers)


class Page(HTMLParser):
    def __init__(self, html):
        super().__init__()
        self.links = []
        self.assets = []
        self.ids = set()
        self.tags = set()
        self.feed(html)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.tags.add(tag)
        if "id" in attrs:
            self.ids.add(attrs["id"])
        if tag == "a" and attrs.get("href"):
            self.links.append(attrs["href"])
        if tag in ("img", "script") and attrs.get("src"):
            self.assets.append(attrs["src"])
        if tag == "link" and attrs.get("href"):
            self.assets.append(attrs["href"])


base = sys.argv[1].rstrip("/")
assert urlsplit(base).scheme in ("http", "https"), "HTTP(S) base URL required"
routes = [
    "/", "/business/", "/support/", "/account-deletion/", "/documents/",
    "/documents/offer/draft-2026-07-29/",
    "/documents/rental-rules/draft-2026-07-29/",
    "/documents/privacy-consent/draft-2026-07-29/",
    "/documents/prohibited-items/2026-07-27.1/",
]
responses = {}
errors = []
opener = build_opener(Redirects())


def fetch(url):
    if url not in responses:
        try:
            with opener.open(url, timeout=10) as response:
                responses[url] = (response.status, response.headers, response.read())
        except HTTPError as error:
            responses[url] = (error.code, error.headers, error.read())
    return responses[url]


for route in routes:
    url = base + route
    status, headers, body = fetch(url)
    if status != 200:
        errors.append(f"{route}: expected 200, got {status}")
        continue
    page = Page(body.decode())
    for href in page.links + page.assets:
        target, fragment = urldefrag(urljoin(url, href))
        if urlsplit(target).netloc != urlsplit(base).netloc:
            continue
        target_status, target_headers, target_body = fetch(target)
        if target_status != 200:
            errors.append(f"{route}: broken {href} ({target_status})")
        elif fragment and "text/html" in target_headers.get("Content-Type", ""):
            if unquote(fragment) not in Page(target_body.decode()).ids:
                errors.append(f"{route}: missing anchor {href}")
    for name, expected in {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "Referrer-Policy": "no-referrer",
        "X-Robots-Tag": "noindex, nofollow",
        "Permissions-Policy": "camera=(), geolocation=(), microphone=(), payment=()",
    }.items():
        if headers.get(name) != expected:
            errors.append(f"{route}: incorrect {name}")
    csp = headers.get("Content-Security-Policy", "")
    legal = route not in ("/", "/business/")
    required = ["default-src 'self'", "frame-ancestors 'none'", "form-action 'none'"]
    required += ["script-src 'none'", "connect-src 'none'"] if legal else ["script-src 'self'"]
    if any(directive not in csp for directive in required):
        errors.append(f"{route}: incorrect CSP")
    if legal and ("unsafe-inline" in csp or page.tags & {"script", "form"}):
        errors.append(f"{route}: legal page permits scripts/forms")
    if route in ("/support/", "/account-deletion/"):
        if "mailto:sosedi.rs@yandex.ru" not in page.links:
            errors.append(f"{route}: missing approved support email")

for route in ("/missing-preview-route/", "/documents/missing/", "/.env"):
    status, headers, _ = fetch(base + route)
    if status != 404:
        errors.append(f"{route}: expected 404, got {status}")
    if route.startswith("/documents/"):
        if "script-src 'none'" not in headers.get("Content-Security-Policy", ""):
            errors.append(f"{route}: missing legal CSP on 404")

if errors:
    sys.exit("\n".join(sorted(set(errors))))
print(f"Public site smoke passed: {len(routes)} routes, links/assets/anchors, headers and 404s")
