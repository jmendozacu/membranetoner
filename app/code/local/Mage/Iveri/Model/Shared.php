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
 * @category   Payments
 * @package    Vcs
 * @copyright  Copyright (c) 2008 W&C Information Consultants CC (http://www.wcic.co.za)
 */

class Mage_Iveri_Model_Shared extends Mage_Payment_Model_Method_Abstract

{

    /**
    * unique internal payment method identifier
    *
    * @var string [a-z0-9_]
    **/
    protected $_code = 'iveri_shared';

    protected $_isGateway               = false;
    protected $_canAuthorize            = true;
    protected $_canCapture              = true;
    protected $_canCapturePartial       = false;
    protected $_canRefund               = false;
    protected $_canVoid                 = false;
    protected $_canUseInternal          = false;
    protected $_canUseCheckout          = true;
    protected $_canUseForMultishipping  = true;

    protected $_paymentMethod           = 'shared';
    protected $_defaultLocale           = 'en';

    protected $_Url;

    protected $_order;

    /**
     * Get order model
     *
     * @return Mage_Sales_Model_Order
     */
    public function getOrder()
    {
        if (!$this->_order) {
            $paymentInfo = $this->getInfoInstance();
            $this->_order = Mage::getModel('sales/order')
                            ->loadByIncrementId($paymentInfo->getOrder()->getRealOrderId());
        }
        return $this->_order;
    }

    /**
     * Get checkout session namespace
     *
     * @return Mage_Checkout_Model_Session
     */
    public function getCheckout()
    {
        return Mage::getSingleton('checkout/session');
    }

    public function getOrderPlaceRedirectUrl()
    {
          return Mage::getUrl('iveri/processing/redirect');
    }

    public function capture(Varien_Object $payment, $amount)
    {
        $payment->setStatus(self::STATUS_APPROVED)
            ->setLastTransId($this->getTransactionId());

        return $this;
    }

    public function cancel(Varien_Object $payment)
    {
        $payment->setStatus(self::STATUS_DECLINED)
            ->setLastTransId($this->getTransactionId());

        return $this;
    }

    /**
     * Return redirect block type
     *
     * @return string
     */
    public function getRedirectBlockType()
    {
        return $this->_redirectBlockType;
    }

    /**
     * Return payment method type string
     *
     * @return string
     */
    public function getPaymentMethodType()
    {
        return $this->_paymentMethod;
    }

    public function getUrl()
    {
    	return $this->_Url;
    }

    /**
     * prepare params array to send it to gateway page via POST
     *
     * @return array
     */
  /*  public function getFormFieldsxxx()
    {
        $amount     = number_format($this->getOrder()->getBaseGrandTotal(),2,'.','');
        $currency   = $this->getOrder()->getBaseCurrencyCode();

        $locale = explode('_', Mage::app()->getLocale()->getLocaleCode());
        if (is_array($locale) && !empty($locale))
            $locale = $locale[0];
        else
            $locale = $this->getDefaultLocale();

        $params = array(
            'p1'        =>  $this->getConfigData('terminal_id'),
            'p2'        =>  $this->getOrder()->getRealOrderId(),
            'p3'        =>  Mage::helper('iveri')->__('Your purchase at') . ' ' . Mage::app()->getStore()->getName(),
            'p4'        =>  $amount,
            'p5'        =>  $currency,
        );

        if ($this->getConfigData('pam') != '') {
            $params['m_1'] = md5($this->getConfigData('pam').'::'.$params['p2']);
        }

        if ($this->getConfigData('pam') != '') {
            $params['pam'] = md5($params['p1'].$params['p2'].$params['p3'].$params['p4'].$params['p5'].$params['m_1'].$this->getConfigData('pam'));
        }

        if ($this->getConfigData('md5') != '') {
            $params['hash'] = md5($params['p1'].$params['p2'].$params['p3'].$params['p4'].$params['p5'].$params['m_1'].$this->getConfigData('md5'));
        }


    	return $params;
    }*/


    /**
     * prepare params array to send it to gateway page via POST
     *
     * @return array
     */
    public function getFormFields() {
        $amount     = number_format($this->getOrder()->getBaseGrandTotal(),2,'','');
        $billing_email = $this->getOrder()->getCustomerEmail();
        $items = $this->getOrder()->getItemsCollection();
        $shippingAmount = $this->getOrder()->getBaseShippingAmount();

        $params = array(
            'Lite_Merchant_ApplicationId'=>$this->getConfigData('terminal_id'),
            'Lite_Order_Amount'=>$amount,
            'Lite_Website_Successful_Url'=>$this->getConfigData('success_url'),
            'Lite_Website_Fail_Url'=>$this->getConfigData('fail_url'),
            'Lite_Website_TryLater_Url'=>$this->getConfigData('fail_url'),
            'Lite_Website_Error_Url'=>$this->getConfigData('fail_url'),
            'Lite_ConsumerOrderID_PreFix'=>$this->getConfigData('order_id_prefix'),
            'Ecom_BillTo_Online_Email'=>$billing_email,
            'Ecom_ConsumerOrderID'=>$this->getOrder()->getRealOrderId(),
            'Ecom_TransactionComplete'=>FALSE,
            'Lite_Authorisation'=>"True",
            'ECOM_PAYMENT_CARD_PROTOCOLS'=>'IVERI'

        );

        $count = count($items);

        $i=1;
        foreach($items as $_item){
            $amount     = number_format($_item->getPrice(),2,'.','');
            $amount = ($amount*1.14);
            $amount =  number_format($amount,2,'','');
            $params['Lite_Order_LineItems_Product_'.$i] = $_item->getName();
            $params['Lite_Order_LineItems_Quantity_'.$i] = $_item->getQtyToInvoice();
            $params['Lite_Order_LineItems_Amount_'.$i] = $amount;
          $i++;
          $tot = $i;
        }

        $params['Lite_Order_LineItems_Product_'.($count+1)] = 'Delivery';
        $params['Lite_Order_LineItems_Quantity_'.($count+1)] = '1';
        $params['Lite_Order_LineItems_Amount_'.($count+1)] = number_format($shippingAmount,2,'','');

//       	echo "<pre>";
//       	print_r($params);
//       	echo "</pre>";
//
//       	die();

    /*  $params['Ecom_Payment_Card_Number']="";
      $params['Ecom_Payment_Card_Verification']="";
        $params['Ecom_Payment_Card_ExpDate_Day']="";
        $params['Ecom_Payment_Card_ExpDate_Year']="";
        $params['Ecom_Payment_Card_Name']="";
      */
        return $params;
    }
}
