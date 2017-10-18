<?php
/**
 * This class overrides the default layout method for PDF Invoice
 * and allows you to add extra features like 
 * - Customization of height & width of Invoice Logo
 * - Header & Footer text can be added 
 * 
 * GuruWebSoft (www.guruwebsoft.com)
 * 
 * @author     MagentoPycho <rajen_k_bhtt@hotmail.com>
 * @category   PDF_Invoice
 * @package    MagentoPycho_PdfInvoice
 */
class MagentoPycho_PdfInvoice_Model_Sales_Order_Pdf_Invoice extends Mage_Sales_Model_Order_Pdf_Invoice
{
    private $_headerTextX = 130;
    
    private function _isCustomInvoiceEnabled(){
        if(Mage::getStoreConfig('sales/mppdfinvoice/active') == 1){
            return true;
        }else{
            return false;
        }
    }
    public function getPdf($invoices = array())
    {
        $this->_beforeGetPdf();
        $this->_initRenderer('invoice');

        $pdf = new Zend_Pdf();
        $this->_setPdf($pdf);
        $style = new Zend_Pdf_Style();
        $this->_setFontBold($style, 10);

        foreach ($invoices as $invoice) {
            if ($invoice->getStoreId()) {
                Mage::app()->getLocale()->emulate($invoice->getStoreId());
            }
            $page = $pdf->newPage(Zend_Pdf_Page::SIZE_A4);
            $pdf->pages[] = $page;

            $order = $invoice->getOrder();

            /* Add image */
            $this->insertLogo($page, $invoice->getStore());
            
            if($this->_isCustomInvoiceEnabled()){
                /* Add Header Text */
                $this->insertHeaderText($page, $invoice->getStore());
            }else{
                /* Add address */
                $this->insertAddress($page, $invoice->getStore());
            }
            

            /* Add head */
            $this->insertOrder($page, $order, Mage::getStoreConfigFlag(self::XML_PATH_SALES_PDF_INVOICE_PUT_ORDER_ID, $order->getStoreId()));


            $page->setFillColor(new Zend_Pdf_Color_GrayScale(1));
            $this->_setFontRegular($page);
            $page->drawText(Mage::helper('sales')->__('Invoice # ') . $invoice->getIncrementId(), 35, 780, 'UTF-8');

            /* Add table */
            $page->setFillColor(new Zend_Pdf_Color_RGB(0.93, 0.92, 0.92));
            $page->setLineColor(new Zend_Pdf_Color_GrayScale(0.5));
            $page->setLineWidth(0.5);

            $page->drawRectangle(25, $this->y, 570, $this->y -15);
            $this->y -=10;

            /* Add table head */
            $page->setFillColor(new Zend_Pdf_Color_RGB(0.4, 0.4, 0.4));
            $page->drawText(Mage::helper('sales')->__('Products'), 35, $this->y, 'UTF-8');
            $page->drawText(Mage::helper('sales')->__('SKU'), 255, $this->y, 'UTF-8');
            $page->drawText(Mage::helper('sales')->__('Price'), 380, $this->y, 'UTF-8');
            $page->drawText(Mage::helper('sales')->__('QTY'), 430, $this->y, 'UTF-8');
            $page->drawText(Mage::helper('sales')->__('Tax'), 480, $this->y, 'UTF-8');
            $page->drawText(Mage::helper('sales')->__('Subtotal'), 535, $this->y, 'UTF-8');

            $this->y -=15;

            $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));

            /* Add body */
            foreach ($invoice->getAllItems() as $item){
                if ($item->getOrderItem()->getParentItem()) {
                    continue;
                }

                if ($this->y < 15) {
                    $page = $this->newPage(array('table_header' => true));
                }

                /* Draw item */
                $page = $this->_drawItem($item, $page, $order);
            }

            /* Add totals */
            $page = $this->insertTotals($page, $invoice);
            
            if($this->_isCustomInvoiceEnabled()){
                /* Add Footer Text */
                $this->insertFooterText($page, $invoice->getStore());
            }
            
            
            if ($invoice->getStoreId()) {
                Mage::app()->getLocale()->revert();
            }
        }

        $this->_afterGetPdf();

        return $pdf;
    }
    
    /**
     * Create new page and assign to PDF object
     *
     * @param array $settings
     * @return Zend_Pdf_Page
     */
    public function newPage(array $settings = array())
    {
        /* Add new table head */
        $page = $this->_getPdf()->newPage(Zend_Pdf_Page::SIZE_A4);
        $this->_getPdf()->pages[] = $page;
        $this->y = 800;

        if (!empty($settings['table_header'])) {
            $this->_setFontRegular($page);
            $page->setFillColor(new Zend_Pdf_Color_RGB(0.93, 0.92, 0.92));
            $page->setLineColor(new Zend_Pdf_Color_GrayScale(0.5));
            $page->setLineWidth(0.5);
            $page->drawRectangle(25, $this->y, 570, $this->y-15);
            $this->y -=10;

            $page->setFillColor(new Zend_Pdf_Color_RGB(0.4, 0.4, 0.4));
            $page->drawText(Mage::helper('sales')->__('Product'), 35, $this->y, 'UTF-8');
            $page->drawText(Mage::helper('sales')->__('SKU'), 255, $this->y, 'UTF-8');
            $page->drawText(Mage::helper('sales')->__('Price'), 380, $this->y, 'UTF-8');
            $page->drawText(Mage::helper('sales')->__('QTY'), 430, $this->y, 'UTF-8');
            $page->drawText(Mage::helper('sales')->__('Tax'), 480, $this->y, 'UTF-8');
            $page->drawText(Mage::helper('sales')->__('Subtotal'), 535, $this->y, 'UTF-8');

            $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));
            $this->y -=20;
        }

        return $page;
    }
    
    protected function insertLogo(&$page, $store = null)
    {
        $image = Mage::getStoreConfig('sales/mppdfinvoice/logo', $store);        
        if ($image) {
            $image = Mage::getStoreConfig('system/filesystem/media', $store) . '/sales/store/logo/' . $image;            
            if (is_file($image)) {
                $dimensions  = getimagesize($image);
                $image = Zend_Pdf_Image::imageWithPath($image);
                
                if($this->_isCustomInvoiceEnabled()){
                    
                    $logo_width  = $dimensions[0];
                    $logo_height = $dimensions[1];
                    
                    $logo_width  = !empty($logo_width) ? $logo_width : 200; 
                    $logo_height = !empty($logo_height) ? $logo_height : 50;   
                    
                    $x2 = (int)(25 + $logo_width / 2);
                    $y2 = (int)(800 + $logo_height / 2); 
                    
                    $this->_headerTextX = $x2 + 5;               
                    $page->drawImage($image, 25, 800, $x2, $y2);
                }else{
                    $page->drawImage($image, 25, 800, 125, 825);    
                }                
            }
        }
        //return $page;
    }
    
    protected function insertHeaderText(&$page, $store = null)
    {
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));
        $this->_setFontRegular($page, 5);

        /*$page->setLineWidth(0.5);
        $page->setLineColor(new Zend_Pdf_Color_GrayScale(0.5));
        $page->drawLine(125, 825, 125, 790);*/

        $page->setLineWidth(0);
        $this->y = 820;
        foreach (explode("\n", Mage::getStoreConfig('sales/mppdfinvoice/header_text', $store)) as $value){
            if ($value!=='') {
                $page->drawText(trim(strip_tags($value)), $this->_headerTextX, $this->y, 'UTF-8');
                $this->y -=7;
            }
        }
        //return $page;
    }
    
    protected function insertFooterText(&$page, $store = null)
    {
        $page->setFillColor(new Zend_Pdf_Color_RGB(0.93, 0.92, 0.92));
        $page->setLineColor(new Zend_Pdf_Color_GrayScale(0.5));
        $page->setLineWidth(0.5);

        $page->drawRectangle(25, $this->y, 570, $this->y - 30);
        $this->y -=10;
        
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));
        $this->_setFontRegular($page);
        
        foreach (explode("\n", Mage::getStoreConfig('sales/mppdfinvoice/footer_text', $store)) as $value){
            if ($value!=='') {
                $page->drawText(trim(strip_tags($value)), 35, $this->y, 'UTF-8');
                $this->y -=7;
            }
        }
        //return $page;
    }    
}
