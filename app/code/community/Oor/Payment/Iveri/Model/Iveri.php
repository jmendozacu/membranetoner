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
 * @category   Mage
 * @package    Mage_Paygate
 * @copyright  Copyright (c) 2004-2007 Irubin Consulting Inc. DBA Varien (http://www.varien.com)
 * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
 */


class Oor_Payment_Iveri_Model_Iveri extends Mage_Payment_Model_Method_Cc
{
    const CGI_URL = 'https://backoffice.iveri.co.za/Lite/Transactions/New/Authorise.aspx';

    const REQUEST_METHOD_CC     = 'CC';
    const REQUEST_METHOD_ECHECK = 'ECHECK';

    const REQUEST_TYPE_AUTH_CAPTURE = 'AUTH_CAPTURE';
    const REQUEST_TYPE_AUTH_ONLY    = 'AUTH_ONLY';
    const REQUEST_TYPE_CAPTURE_ONLY = 'CAPTURE_ONLY';
    const REQUEST_TYPE_CREDIT       = 'CREDIT';
    const REQUEST_TYPE_VOID         = 'VOID';
    const REQUEST_TYPE_PRIOR_AUTH_CAPTURE = 'PRIOR_AUTH_CAPTURE';

    const ECHECK_ACCT_TYPE_CHECKING = 'CHECKING';
    const ECHECK_ACCT_TYPE_BUSINESS = 'BUSINESSCHECKING';
    const ECHECK_ACCT_TYPE_SAVINGS  = 'SAVINGS';

    const ECHECK_TRANS_TYPE_CCD = 'CCD';
    const ECHECK_TRANS_TYPE_PPD = 'PPD';
    const ECHECK_TRANS_TYPE_TEL = 'TEL';
    const ECHECK_TRANS_TYPE_WEB = 'WEB';

    const RESPONSE_DELIM_CHAR = ' ';

    const RESPONSE_CODE_APPROVED = 0;
    const RESPONSE_CODE_DECLINED = 10;
    const RESPONSE_CODE_ERROR    = 255;
    const RESPONSE_CODE_NETWORK_1 = 1;
    const RESPONSE_CODE_NETWORK_2 = 2;
    const RESPONSE_CODE_NETWORK_3 = 5;
    const RESPONSE_CODE_NETWORK_4 = 9;
    const RESPONSE_CODE_HELD     = 4;
    
    const SUCCESSFUL_URL = 'http://www.toner.webfanatix.co.za/result.php?Result=Success';
    const FAIL_URL = 'http://www.toner.webfanatix.co.za/result.php?Result=Fail';
    const LATER_URL = 'http://www.toner.webfanatix.co.za/result.php?Result=TryLater';
    const ERROR_URL = 'http://www.toner.webfanatix.co.za/result.php?Result=Error';
    
    const PROTOCOL = 'IVERI';
    const TRANSACTION_COMPLETE = 'FALSE';

    protected $_code  = 'iveri';

    /**
     * Availability options
     */
    protected $_isGateway               = true;
    protected $_canAuthorize            = true;
    protected $_canCapture              = true;
    protected $_canCapturePartial       = false;
    protected $_canRefund               = false;
    protected $_canVoid                 = true;
    protected $_canUseInternal          = true;
    protected $_canUseCheckout          = true;
    protected $_canUseForMultishipping  = true;
    protected $_canSaveCc = false;

    /**
     * Send authorize request to gateway
     *
     * @param   Varien_Object $payment
     * @param   decimal $amount
     * @return  Mage_Paygate_Model_Authorizenet
     */
    public function authorize(Varien_Object $payment, $amount)
    {
        $error = false;
        if($amount>0){
            $payment->setAnetTransType(self::REQUEST_TYPE_AUTH_ONLY);
            $payment->setAmount($amount);

            $request= $this->_buildRequest($payment);
            $result = $this->_postRequest($request);

            $payment->setCcApproval($result->getApprovalCode())
                ->setLastTransId($result->getTransactionId())
                ->setCcTransId($result->getTransactionId());

            switch ($result->getResponseCode()) {
                case self::RESPONSE_CODE_APPROVED:
                    $payment->setStatus(self::STATUS_APPROVED);
                    break;
                case self::RESPONSE_CODE_ERROR:
                    $error = Mage::helper('paygate')->__('Payment authorization error.');
                    $error = RESPONSE_REASON;
                    break;
                case self::RESPONSE_CODE_NETWORK_1:
                    $error = Mage::helper('paygate')->__('Payment authorization network failure.');
                    break;
                case self::RESPONSE_CODE_NETWORK_2:
                    $error = Mage::helper('paygate')->__('Payment authorization network failure.');
                    break;
                case self::RESPONSE_CODE_NETWORK_3:
                    $error = Mage::helper('paygate')->__('Payment authorization network failure.');
                    break;
                case self::RESPONSE_CODE_NETWORK_4:
                    $error = Mage::helper('paygate')->__('Payment authorization network failure.');
                    break;
                default:
                    $error = Mage::helper('paygate')->__('Payment authorization transaction has been declined.');
                    break;
            }
        }else{
            $error = Mage::helper('paygate')->__('Invalid amount for authorization.');
        }

        if ($error !== false) {
            Mage::throwException($error);
        }
        return $this;
    }


    public function capture(Varien_Object $payment, $amount)
    {
        $error = false;

        if ($payment->getCcTransId()) {
            $payment->setAnetTransType(self::REQUEST_TYPE_PRIOR_AUTH_CAPTURE);
        } else {
            $payment->setAnetTransType(self::REQUEST_TYPE_AUTH_CAPTURE);
        }

        $payment->setAmount($amount);

        $request= $this->_buildRequest($payment);
        
        $result = $this->_postRequest($request);
        
        if ($result->getResponseCode() == self::RESPONSE_CODE_APPROVED) {
            $payment->setStatus(self::STATUS_APPROVED);
            //$payment->setCcTransId($result->getTransactionId());
            $payment->setLastTransId($result->getTransactionId());
        }
        else {
            if ($result->getResponseReasonText()) {
                $error = $result->getResponseReasonText();
            }
            else {
                $error = Mage::helper('paygate')->__('Error in capturing the payment');
            }
        }

        if ($error !== false) {
            Mage::throwException($error);
        }

        return $this;
    }


    /**
     * void
     *
 * @author      Magento Core Team <core@magentocommerce.com>
     * @access public
     * @param string $payment Varien_Object object
     * @return Mage_Payment_Model_Abstract
     */
    public function void(Varien_Object $payment)
    {
        $error = false;
        if($payment->getVoidTransactionId()){
            $payment->setAnetTransType(self::REQUEST_TYPE_VOID);
            $request = $this->_buildRequest($payment);
						$request->setXTransId($payment->getVoidTransactionId());
            $result = $this->_postRequest($request);
            if($result->getResponseCode()==self::RESPONSE_CODE_APPROVED){
                 $payment->setStatus(self::STATUS_SUCCESS );
            }
            else{
                $payment->setStatus(self::STATUS_ERROR);
                $error = $result->getResponseReasonText();
            }
        }else{
            $payment->setStatus(self::STATUS_ERROR);
            $error = Mage::helper('paygate')->__('Invalid transaction id');
        }
        if ($error !== false) {
            Mage::throwException($error);
        }
        return $this;
    }

    /**
     * refund the amount with transaction id
     *
     * @access public
     * @param string $payment Varien_Object object
     * @return Mage_Payment_Model_Abstract
     */
    public function refund(Varien_Object $payment, $amount)
    {
        $error = false;
        if ($payment->getRefundTransactionId() && $amount>0) {
            $payment->setAnetTransType(self::REQUEST_TYPE_CREDIT);
            $request = $this->_buildRequest($payment);
            $request->setXTransId($payment->getRefundTransactionId());
            $result = $this->_postRequest($request);

            if ($result->getResponseCode()==self::RESPONSE_CODE_APPROVED) {
                $payment->setStatus(self::STATUS_SUCCESS);
            } else {
                $error = $result->getResponseReasonText();
            }

        } else {
            $error = Mage::helper('paygate')->__('Error in refunding the payment');
        }

        if ($error !== false) {
            Mage::throwException($error);
        }
        return $this;
    }

    /**
     * Prepare request to gateway
     *
     * @link http://www.authorize.net/support/AIM_guide.pdf
     * @param Mage_Sales_Model_Document $order
     * @return unknown
     */
    protected function _buildRequest(Varien_Object $payment)
    {
        $order = $payment->getOrder();

        if (!$payment->getAnetTransMethod()) {
            $payment->setAnetTransMethod(self::REQUEST_METHOD_CC);
        }

        $request = new Oor_Payment_Iveri_Model_Request();
        $request->setPostVariable('LiteMerchantApplicationid', array($this->getConfigData('app_id')))
            ->setPostVariable('LiteConsumerorderidPrefix', array($this->getConfigData('inv_pre')))
                 ->setPostVariable('LiteAuthorisation', array('true'));
            
        if($payment->getAmount()){
        	$orderAmount=$this->format_number($payment->getAmount());
        	
                if(preg_match("/\./",$orderAmount)){
                        $a_arr = explode('.', $orderAmount);
                       
                        //$orderAmount = (count($a_arr[1]) < 2) ? $a_arr[0].$a_arr[1].'0' : $a_arr[0].$a_arr[1];
                       
                        $orderAmount=str_replace('.', '', $orderAmount);
                }else{
                    $orderAmount.='00';
                }
            $request->setPostVariable('LiteOrderAmount', array($orderAmount,2));
        }
        
        $request->setLiteWebsiteSuccessfulUrl(self::SUCCESSFUL_URL)
        	->setPostVariable('LiteWebsiteFailUrl', array(self::FAIL_URL))
        	->setPostVariable('LiteWebsiteTrylaterUrl', array(self::LATER_URL))
        	->setPostVariable('LiteWebsiteErrorUrl', array(self::ERROR_URL));

        if (!empty($order)) {
            $request->setPostVariable('EcomConsumerorderid', array($order->getIncrementId()));
	        
            $billing = $order->getBillingAddress();
            if (!empty($billing)) {
                $request->setPostVariable('EcomBilltoPostalNameFirst', array($billing->getFirstname()))
                    ->setPostVariable('EcomBilltoPostalNameLast', array($billing->getLastname()))
                    ->setPostVariable('EcomBilltoPostalStreetLine1', array($billing->getStreet(1)))
                    ->setPostVariable('EcomBilltoPostalCity', array($billing->getCity()))
                    ->setPostVariable('EcomBilltoPostalStateprov', array($billing->getRegion()))
                    ->setPostVariable('EcomBilltoPostalPostalcode', array($billing->getPostcode()))
                    ->setPostVariable('EcomBilltoTelecomPhoneNumber', array($billing->getTelephone()))
                    ->setPostVariable('EcomBilltoOnlineEmail', array($order->getCustomerEmail()));
            }

            $shipping = $order->getShippingAddress();
            if (!empty($shipping)) {
                $request->setPostVariable('EcomShiptoPostalNameFirst', array($shipping->getFirstname()))
                    ->setPostVariable('EcomShiptoPostalNameLast', array($shipping->getLastname()))
                    ->setPostVariable('EcomShiptoPostalStreetLine1', array($shipping->getStreet(1)))
                    ->setPostVariable('EcomShiptoPostalCity', array($shipping->getCity()))
                    ->setPostVariable('EcomShiptoPostalStateprov', array($shipping->getRegion()))
                    ->setPostVariable('EcomShiptoPostalPostalcode', array($shipping->getPostcode()));
            }

            $items=$order->getItemsCollection();
	        $start_number=1;
                
	        foreach($items as $item){
                    
	        	$itemPrice=$item->getPrice();
                        
	        	if(preg_match("/\./",$itemPrice)) {
                            //$itemPrice=str_replace('.', '', $itemPrice);
                            $a_arr = explode('.', $itemPrice);
                       
                        $itemPrice = (count($a_arr[1]) < 2) ? $a_arr[0].$a_arr[1].'0':$a_arr[0].$a_arr[1];
                            
                        }else 
                        {
                            $itemPrice.='00';
                        }
                        
	        	$request->setPostVariable("LiteOrderLineitemsProduct_$start_number", array($item->getName()))
	        		->setPostVariable("LiteOrderLineitemsQuantity_$start_number", array($item->getQtyToInvoice()))
	        		->setPostVariable("LiteOrderLineitemsAmount_$start_number", array( $itemPrice*1.14 ));
				$start_number++;
	        }
	        $shippingAmount=round($order->getShippingAmount());
	        $shippingAmount.='00';
	        $request->setPostVariable("LiteOrderLineitemsProduct_$start_number", array('Delivery'))
	        		->setPostVariable("LiteOrderLineitemsQuantity_$start_number", array(1))
	        		->setPostVariable("LiteOrderLineitemsAmount_$start_number", array($shippingAmount));
        }

        switch ($payment->getAnetTransMethod()) {
            case self::REQUEST_METHOD_CC:
                if($payment->getCcNumber()){
                    $request->setPostVariable("EcomPaymentCardNumber", array($payment->getCcNumber()))
                    	->setPostVariable("EcomPaymentCardExpdateMonth", array($payment->getCcExpMonth()))
                    	->setPostVariable("EcomPaymentCardExpdateYear", array($payment->getCcExpYear()));
                }
                break;

            case self::REQUEST_METHOD_ECHECK:
                $request->setXBankAbaCode($payment->getEcheckRoutingNumber())
                    ->setXBankName($payment->getEcheckBankName())
                    ->setXBankAcctNum($payment->getEcheckAccountNumber())
                    ->setXBankAcctType($payment->getEcheckAccountType())
                    ->setXBankAcctName($payment->getEcheckAccountName())
                    ->setXEcheckType($payment->getEcheckType());
                break;
        }

        $request->setPostVariable("EcomPaymentCardProtocols", array(self::PROTOCOL))
        	->setPostVariable("EcomTransactioncomplete", array(self::TRANSACTION_COMPLETE));
        	
        return $request;
    }

    protected function _postRequest(Varien_Object $request, $auth=false)
    {		
    
        $result = Mage::getModel('paygate/authorizenet_result');

        $client = new Oor_Payment_Iveri_Http_Client();

        $uri = $this->getConfigData('cgi_url');
        $client->setUri($uri ? $uri : self::CGI_URL);
        $client->setConfig(array(
            'maxredirects'=>8,
            'timeout'=>30,
            //'ssltransport' => 'tcp',
        ));
    	
        $client->setParameterPost($request->getData());
        $client->setMethod(Zend_Http_Client::POST);

       // if ($this->getConfigData('debug')) {
            foreach( $request->getData() as $key => $value ) {
                $requestData[] = strtoupper($key) . '=' . $value;
            }

            $requestData = join('&', $requestData);

            $debug = Mage::getModel('paygate/authorizenet_debug')
                ->setRequestBody($requestData)
                ->setRequestSerialized(serialize($request->getData()))
                ->setRequestDump(print_r($request->getData(),1))
                ->save();
       // }
        
        
        try {
            $response = $client->request();
            
        } catch (Exception $e) {
            
            $result->setResponseCode(-1)
                ->setResponseReasonCode($e->getCode())
                ->setResponseReasonText($e->getMessage());

            if (!empty($debug)) {
                $debug
                    ->setResultSerialized(serialize($result->getData()))
                    ->setResultDump(print_r($result->getData(),1))
                    ->save();
            }
            Mage::throwException(
                Mage::helper('paygate')->__('Gateway request error: %s', $e->getMessage())
            );
        }

        $responseBody = $response->getBody();
        
        if($auth==false){
	        $ir = explode("id=\"__VIEWSTATE\" value=\"", $responseBody);
                
			$ir = explode("\" />", $ir[1]);
			$irValue = $ir[0];
			
			$request = new Oor_Payment_iVeri_Model_Request();
	        $request->setPostVariable('__viewstate', array($irValue));
	        $this->_postRequest($request, true);
        }
        
        $r = explode(self::RESPONSE_DELIM_CHAR, $responseBody);
        
        
        
        $responseFields = array(
    	"id=\"LITE_PAYMENT_CARD_STATUS\"",
    	"id=\"LITE_TRANSACTIONDATE\"",
    	"id=\"LITE_TRANSACTIONINDEX\"",
    	"id=\"LITE_RESULT_DESCRIPTION\"",
    	"id=\"LITE_BANKREFERENCE\"",
    	"id=\"ECOM_CONSUMERORDERID\"",
    	"id=\"LITE_ORDER_AMOUNT\"",
    	"id=\"LITE_ORDER_AUTHORISATIONCODE\"",
    	"id=\"ECOM_PAYMENT_CARD_PROTOCOLS\"",
    	"id=\"NPAY_TRANSACTIONTYPE\"");
    	
    	for($i=0; $i<count($responseFields); $i++){
			$matchKey=array_search($responseFields[$i], $r);
			if($matchKey!==false){
                                
				$fieldValue=$r[$matchKey+1];
                                
				if(preg_match("/value=\"/", $fieldValue)){
					$extractValue=explode("value=\"", $fieldValue);
					$extractValue=explode("\"", $extractValue[1]);
					$fieldData=$extractValue[0];
					if(count($extractValue)==1){
						$nextValue=$r[$matchKey+2];
						$nextValue=str_replace("\"", "", $nextValue);
						$fieldData.= " $nextValue";
					}
				}else{
					$fieldData = ' ';
				}
				
				switch ($i){
					case 0:
						define("RESPONSE_CODE", $fieldData);
						break;
					case 1:
						define("TRANSACTION_DATE", $fieldData);
						break;
					case 2:
						define("TRANSACTION_ID", $fieldData);
						break;
					case 3:
						define("RESPONSE_REASON", $fieldData);
                                                $response_reason = $responseBody;
						break;
					case 4:
                                            $val = $fieldData ? $fieldData: 'none';
						define("BANK_REFERENCE", $val);
						break;
					case 5:
						define("INVOICE_NUMBER", $fieldData);
						break;
					case 6:
						define("RESPONSE_AMOUNT", $fieldData);
						break;
					case 7:
						define("APPROVAL_CODE", $fieldData);
						break;
					case 8:
						define("RESPONSE_METHOD", $fieldData);
						break;
					case 9:
						define("TRANSACTION_TYPE", $fieldData);
						break;
				}
			}
		}
        
        if ($r) {
            $result->setResponseCode((int)RESPONSE_CODE)
                ->setResponseReasonText(RESPONSE_REASON)
                ->setApprovalCode(APPROVAL_CODE)
                ->setTransactionId(TRANSACTION_ID)
                ->setTransactionDate(TRANSACTION_DATE)
                ->setBankReference(BANK_REFERENCE)
                ->setInvoiceNumber(INVOICE_NUMBER)
                ->setAmount(RESPONSE_AMOUNT)
                ->setMethod(RESPONSE_METHOD)
                ->setTransactionType(TRANSACTION_TYPE);
        } else {
             Mage::throwException(
                Mage::helper('paygate')->__('Error in payment gateway')
            );
        }

        if (!empty($debug)) {
            $debug
                ->setResponseBody($responseBody)
                ->setResultSerialized(serialize($result->getData()))
                ->setResultDump(print_r($result->getData(),1))
                ->save();
        }

        
        return $result;
    }
    
    
    
     public   function format_number($str,$decimal_places='2',$decimal_padding="0"){
            /* firstly format number and shorten any extra decimal places */
            /* Note this will round off the number pre-format $str if you dont want this fucntionality */
            $str           =  number_format($str,$decimal_places,'.','');     // will return 12345.67
            $number       = explode('.',$str);
            $number[1]     = (isset($number[1]))?$number[1]:''; // to fix the PHP Notice error if str does not contain a decimal placing.
            $decimal     = str_pad($number[1],$decimal_places,$decimal_padding);
            return (float) $number[0].'.'.$decimal;
    }
}