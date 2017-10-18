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
 * @package    Iveri
 * @copyright
 */

class Mage_Iveri_ProcessingController extends Mage_Core_Controller_Front_Action
{
    protected $_redirectBlockType = 'iveri/processing';
    protected $_successBlockType = 'iveri/success';
    protected $_failureBlockType = 'iveri/failure';

    protected $_sendNewOrderEmail = true;

    protected $_order = NULL;
    protected $_paymentInst = NULL;

    protected function _expireAjax()
    {
        if (!$this->getCheckout()->getQuote()->hasItems()) {
            $this->getResponse()->setHeader('HTTP/1.1','403 Session Expired');
            exit;
        }
    }

    /**
     * Get singleton of Checkout Session Model
     *
     * @return Mage_Checkout_Model_Session
     */
    public function getCheckout()
    {
        return Mage::getSingleton('checkout/session');
    }

    /**
     * when customer select VCS payment method
     */
    public function redirectAction()
    {
        $session = $this->getCheckout();
        $session->setVcsQuoteId($session->getQuoteId());
        $session->setVcsRealOrderId($session->getLastRealOrderId());

        $order = Mage::getModel('sales/order');
        $order->loadByIncrementId($session->getLastRealOrderId());
        $order->addStatusToHistory(Mage_Sales_Model_Order::STATE_HOLDED,
                Mage::helper('iveri')->__('Customer was redirected to Iveri'));
        $order->save();

        $this->getResponse()->setBody(
            $this->getLayout()
                ->createBlock($this->_redirectBlockType)
                ->setOrder($order)
                ->toHtml()
        );

        $session->unsQuoteId();
    }

    /**
     * Iveri returns POST variables to this action
     */
    public function responseAction()
    {

        $session = $this->getCheckout();
        try {
            $request = $this->_checkReturnedPost();

            // save transaction ID
            $this->_paymentInst->setTransactionId($request['ECOM_CONSUMERORDERID']);

            if ($this->_order->canInvoice()) {
                $invoice = $this->_order->prepareInvoice();
                $invoice->register()->capture();
                Mage::getModel('core/resource_transaction')
                    ->addObject($invoice)
                    ->addObject($invoice->getOrder())
                    ->save();
            }

            $this->_order->addStatusToHistory(
                $this->_paymentInst->getConfigData('order_status'),
                Mage::helper('iveri')->__('Customer returned successfully.').'<br/>'.
                Mage::helper('iveri')->__('Result: Success ')."<br /> Bank Ref: ".$request['LITE_BANKREFERENCE']."<br /> Transaction Index: ".$request['LITE_TRANSACTIONINDEX']);

            $this->_order->save();

            if($this->_order->getId() && $this->_sendNewOrderEmail)
                $this->_order->sendNewOrderEmail();

            $this->loadLayout();
            $this->renderLayout();

        } catch (Exception $e) {
            //echo $e->getMessage();exit();
            $session->addError( Mage::helper('iveri')->__($e->getMessage()) );
            //$this->_redirect('iveri/processing/failure');
            $this->_forward('failure') ;
        }
    }

    /**
     * Vcs return action
     */
    protected function successAction()
    {
        $session = $this->getCheckout();

        $session->unsVcsRealOrderId();
        $session->setQuoteId($session->getVcsQuoteId(true));

        $session->getQuote()->setIsActive(false)->save();

        $order = Mage::getModel('sales/order');
        $order->load($this->getCheckout()->getLastOrderId());

        if($order->getId() && $this->_sendNewOrderEmail)
            $order->sendNewOrderEmail();
    }

    /**
     * Vcs return action
     */
    protected function failureAction()
    {
        $session = $this->getCheckout();
        $session->getMessages(true);
//        if (!$this->getRequest()->isPost()) {
//            $session->addError( 'Wrong request type.' );
//        } else {
            $request = $this->getRequest()->getPost();

            $session->addError( Mage::helper('iveri')->__($request['LITE_RESULT_DESCRIPTION']) );

            $this->_order = Mage::getModel('sales/order')->loadByIncrementId($request['ECOM_CONSUMERORDERID']);
            $this->_paymentInst = $this->_order->getPayment()->getMethodInstance();
            $this->_paymentInst->setTransactionId($request['ECOM_CONSUMERORDERID']);
//        }

        $messages = $session->getMessages();
        $errors = false;
        if ($messages) {
            foreach( $messages->getErrors() as $msg ) {
                $errors[] = $msg->toString();
            }
        }

        if (isset($request) && $request['LITE_PAYMENT_CARD_STATUS'] != '0') {
            $this->_order->addStatusToHistory(
                Mage_Sales_Model_Order::STATE_CANCELED,
                "Failure from iveri<br/>".
                    (is_array($errors)?implode("<br/>",$errors):'No extra information'));
            $this->_order->cancel();
        }

        $this->loadLayout();
        $this->_initLayoutMessages('checkout/session');
        $this->renderLayout();
    }

    /**
     * Checking POST variables.
     * Creating invoice if payment was successfull or cancel order if payment was declined
     */
    protected function _checkReturnedPost()
    {
        // check request type
        if (!$this->getRequest()->isPost())
            throw new Exception('Wrong request type.', 10);

        // get request variables
        $request = $this->getRequest()->getPost();
        if (empty($request))
        	throw new Exception('Request doesn\'t contain POST elements.', 20);

        // check order id
        if ( empty($request['ECOM_CONSUMERORDERID']) ){
            throw new Exception('Missing or invalid order ID', 40);
        }
        // load order for further validation
        $this->_order = Mage::getModel('sales/order')->loadByIncrementId($request['ECOM_CONSUMERORDERID']);
        $this->_paymentInst = $this->_order->getPayment()->getMethodInstance();




        // check transaction amount
        if (number_format($this->_order->getBaseGrandTotal(),2,'','') != $request['LITE_ORDER_AMOUNT'])
            throw new Exception('Transaction amount doesn\'t match.');

        //$params['m_1'] = md5($this->_paymentInst->getConfigData('pam').'::'.$request['p2']);

        return $request;
    }
}
