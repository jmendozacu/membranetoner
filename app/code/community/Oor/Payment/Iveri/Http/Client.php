<?php
/**
 * Magento
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the Open Software License (OSL 3.0)
 * that is bundled with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://opensource.org/licenses/osl-3.0.php
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@magentocommerce.com so we can send you a copy immediately.
 *
 * @category   Varien
 * @package    Varien_Http
 * @copyright  Copyright (c) 2004-2007 Irubin Consulting Inc. DBA Varien (http://www.varien.com)
 * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
 */

/**
 * Varien HTTP Client
 *
 * @category   Varien
 * @package    Varien_Http
 * @author      Magento Core Team <core@magentocommerce.com>
 */
class Oor_Payment_Iveri_Http_Client extends Zend_Http_Client
{
    protected $_urlEncodeBody = true;

    public function __construct($uri = null, $config = null)
    {
        $this->config['useragent'] = 'Varien_Http_Client';

        parent::__construct($uri, $config);
    }

    protected function _trySetCurlAdapter()
    {
        if (extension_loaded('curl')) {
            $this->setAdapter(new Varien_Http_Adapter_Curl());
        }
        return $this;
    }

    public function request($method = null)
    {
        $this->_trySetCurlAdapter();
        
        if (! $this->uri instanceof Zend_Uri_Http) {
            require_once 'Zend/Http/Client/Exception.php';
            throw new Zend_Http_Client_Exception('No valid URI has been passed to the client');
        }

        if ($method) $this->setMethod($method);
        $this->redirectCounter = 0;
        $response = null;

        // Make sure the adapter is loaded
        if ($this->adapter == null) $this->setAdapter($this->config['adapter']);

        // Send the first request. If redirected, continue.
        do {
            // Clone the URI and add the additional GET parameters to it
            $uri = clone $this->uri;
            if (! empty($this->paramsGet)) {
                $query = $uri->getQuery();
                   if (! empty($query)) $query .= '&';
                $query .= http_build_query($this->paramsGet, null, '&');

                $uri->setQuery($query);
            }

            $body = $this->prepare_body();
            $headers = $this->_prepareHeaders();

            // Open the connection, send the request and read the response
            $this->adapter->connect($uri->getHost(), $uri->getPort(),
                ($uri->getScheme() == 'https' ? true : false));

            $this->last_request = $this->adapter->write($this->method,
                $uri, $this->config['httpversion'], $headers, $body);

            $response = $this->adapter->read();
            if (! $response) {
                require_once 'Zend/Http/Client/Exception.php';
                throw new Zend_Http_Client_Exception('Unable to read response, or response is empty');
            }

            $response = Zend_Http_Response::fromString($response);
            if ($this->config['storeresponse']) $this->last_response = $response;

            // Load cookies into cookie jar
            if (isset($this->cookiejar)) $this->cookiejar->addCookiesFromResponse($response, $uri);

            // If we got redirected, look for the Location header
            if ($response->isRedirect() && ($location = $response->getHeader('location'))) {

                // Check whether we send the exact same request again, or drop the parameters
                // and send a GET request
                if ($response->getStatus() == 303 ||
                   ((! $this->config['strictredirects']) && ($response->getStatus() == 302 ||
                       $response->getStatus() == 301))) {

                    $this->resetParameters();
                    $this->setMethod(self::GET);
                }

                // If we got a well formed absolute URI
                if (Zend_Uri_Http::check($location)) {
                    $this->setHeaders('host', null);
                    $this->setUri($location);

                } else {

                    // Split into path and query and set the query
                    if (strpos($location, '?') !== false) {
                        list($location, $query) = explode('?', $location, 2);
                    } else {
                        $query = '';
                    }
                    $this->uri->setQuery($query);

                    // Else, if we got just an absolute path, set it
                    if(strpos($location, '/') === 0) {
                        $this->uri->setPath($location);

                        // Else, assume we have a relative path
                    } else {
                        // Get the current path directory, removing any trailing slashes
                        $path = $this->uri->getPath();
                        $path = rtrim(substr($path, 0, strrpos($path, '/')), "/");
                        $this->uri->setPath($path . '/' . $location);
                    }
                }
                ++$this->redirectCounter;

            } else {
                // If we didn't get any location, stop redirecting
                break;
            }

        } while ($this->redirectCounter < $this->config['maxredirects']);

        return $response;
    }

    public function setUrlEncodeBody($flag)
    {
        $this->_urlEncodeBody = $flag;
        return $this;
    }

    protected function prepare_body()
    {
        $body = parent::_prepareBody();

        if (!$this->_urlEncodeBody && $body) {
            $body = urldecode($body);
            $this->setHeaders('Content-length', strlen($body));
        }

        return $body;
    }
}