# frozen_string_literal: true

shared_examples "saves attributes to census config" do
  it "returns a valid response" do
    expect { command.call }.to broadcast(:ok)
  end

  it "does not enqueues a job" do
    expect { command.call }.not_to have_enqueued_job(Decidim::TrustedIds::System::PropagateCensusConfigJob)
  end

  it "creates trusted_ids_census_config" do
    expect { command.call }.to(change(Decidim::TrustedIds::OrganizationConfig, :count).by(1))
  end

  it "has the correct trusted_ids_census_config" do
    perform_enqueued_jobs { command.call }
    expect(organization.trusted_ids_census_config.settings).to eq(trusted_ids_census_settings)
    expect(organization.trusted_ids_census_config.expiration_days).to eq(trusted_ids_census_expiration_days)
    expect(organization.trusted_ids_census_config.tos).to eq(trusted_ids_census_tos)
    expect(another_organization.trusted_ids_census_config).to be_nil
  end

  context "when expiration days is set to propagate" do
    let(:expiration_all_tenants) { true }

    it "enqueues a job" do
      expect { command.call }.to have_enqueued_job(Decidim::TrustedIds::System::PropagateCensusConfigJob)
    end

    it "saves expiration days in all tenants" do
      expect do
        perform_enqueued_jobs { command.call }
      end.to(change(Decidim::TrustedIds::OrganizationConfig, :count).by(2))

      expect(organization.trusted_ids_census_config.expiration_days).to eq(30)
      expect(organization.trusted_ids_census_config.tos).to eq(trusted_ids_census_tos)
      expect(another_organization.trusted_ids_census_config.expiration_days).to eq(30)
      expect(another_organization.trusted_ids_census_config.tos).not_to eq(trusted_ids_census_tos)
    end
  end

  context "when the other configuration already exists" do
    let!(:trusted_ids_organization_config) { create(:trusted_ids_organization_config, organization: another_organization, expiration_days: 30) }
    let(:trusted_ids_census_expiration_days) { "" }

    it "updates only the subject organization" do
      perform_enqueued_jobs { command.call }

      expect(organization.trusted_ids_census_config.expiration_days).to be_nil
      expect(another_organization.trusted_ids_census_config.expiration_days).to eq(30)
    end

    context "when propagates" do
      let(:expiration_all_tenants) { true }

      it "updates all organizations" do
        perform_enqueued_jobs { command.call }

        expect(organization.trusted_ids_census_config.expiration_days).to be_nil
        expect(another_organization.trusted_ids_census_config.expiration_days).to be_nil
      end
    end
  end

  context "when tos is set to propagate" do
    let(:tos_all_tenants) { true }

    it "enqueues a job" do
      expect { command.call }.to have_enqueued_job(Decidim::TrustedIds::System::PropagateCensusConfigJob)
    end

    it "saves tos in all tenants" do
      expect do
        perform_enqueued_jobs { command.call }
      end.to(change(Decidim::TrustedIds::OrganizationConfig, :count).by(2))

      expect(organization.trusted_ids_census_config.tos).to eq(trusted_ids_census_tos)
      expect(another_organization.trusted_ids_census_config.tos).to eq(trusted_ids_census_tos)
      expect(organization.trusted_ids_census_config.expiration_days).to eq(trusted_ids_census_expiration_days)
      expect(another_organization.trusted_ids_census_config.expiration_days).not_to eq(trusted_ids_census_expiration_days)
    end
  end

  context "when the other configuration already exists" do
    let!(:trusted_ids_organization_config) { create(:trusted_ids_organization_config, organization: another_organization, tos: { "en" => "Some existing text for TOS" }) }
    let(:trusted_ids_census_tos) { {} }

    it "updates only the subject organization" do
      perform_enqueued_jobs { command.call }

      expect(organization.trusted_ids_census_config.tos).to eq({})
      expect(another_organization.trusted_ids_census_config.tos).to eq({ "en" => "Some existing text for TOS" })
    end

    context "when propagates" do
      let(:tos_all_tenants) { true }

      it "updates all organizations" do
        perform_enqueued_jobs { command.call }

        expect(organization.trusted_ids_census_config.tos).to eq({})
        expect(another_organization.trusted_ids_census_config.tos).to eq({})
      end
    end
  end
end
