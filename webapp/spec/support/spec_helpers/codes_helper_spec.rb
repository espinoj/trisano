module CodeSpecHelper

  def given_external_codes(code_name, the_codes, options={})
    given_code_name(code_name, true)
    the_codes.each do |the_code|
      code = external_code!(code_name, the_code, options)
      yield(code) if block_given?
    end
  end

  def given_codes(code_name, the_codes)
    given_code_name(code_name, false)
    the_codes.each do |the_code|
      code = code!(code_name, the_code)
      yield(code) if block_given?
    end
  end

  def given_disease_specific_external_codes(disease_name, code_name, the_codes)
    given_code_name(code_name)
    disease = disease!(disease_name)
    given_external_codes(code_name, the_codes, :disease_specific => true) do |code|
      disease.disease_specific_selections.create(:external_code => code, :rendered => true)
    end
    disease
  end

  def given_code_name(code_name, external=true)
    CodeName.delete_all(['code_name = ?', code_name])
    Factory.create(:code_name, :code_name => code_name, :external => external)
  end
end
